# AI Pose Coach - Data Storage Architecture

## Overview
The AI Pose Coach feature uses a **dual-storage strategy** to save workout session data:
1. **Firebase Firestore** - Primary user-facing storage
2. **MySQL Backend** - Analytics and AI processing

Both systems use the **same Firebase Authentication user ID** to maintain data consistency.

---

## User ID Strategy

### Firebase User ID
- Source: `authProvider.firebaseUser?.uid`
- Format: String (Firebase UID)
- Example: `"abc123def456ghi789"`

### Usage Across Systems:
```dart
// Frontend (Flutter)
final userId = authProvider.firebaseUser?.uid ?? '';

// Firebase Firestore
collection('users').doc(userId).collection('workoutSessions')

// Backend API (MySQL)
user_health_profiles.userId = userId
workout_sessions.user_id = userId (foreign key)
```

---

## Data Flow

### When Workout Completes:

```
User Stops Workout
    ↓
PoseCoachProvider.stopWorkout(userId)
    ↓
    ├─→ Save to Firebase Firestore (Primary)
    │   └─→ PoseFirebaseService.saveWorkoutSession()
    │       └─→ users/{userId}/workoutSessions/{sessionId}
    │
    └─→ Send to Backend API (Analytics)
        └─→ ApiService.sendWorkoutSummary()
            └─→ POST /api/workout/pose-summary
                └─→ MySQL workout_sessions table
```

---

## Firebase Firestore Structure

### Collection Path:
```
users/{userId}/workoutSessions/{sessionId}
```

### Document Schema:
```json
{
  "sessionId": "auto-generated-id",
  "userId": "firebase-user-uid",
  "exercise": "squat",
  "reps": 15,
  "accuracy": 0.87,
  "timestamp": "2025-10-17T14:30:00.000Z",
  "duration": 120,
  "feedbackPoints": ["Keep knees aligned", "Great depth"],
  "createdAt": "2025-10-17T14:32:00.000Z" (server timestamp)
}
```

### Available Methods:

#### Save Workout Session
```dart
await _firebaseService.saveWorkoutSession(
  userId: userId,
  session: session,
);
```

#### Get All User Sessions
```dart
List<Map<String, dynamic>> sessions = 
  await _firebaseService.getUserWorkoutSessions(userId);
```

#### Get Today's Sessions
```dart
List<Map<String, dynamic>> todaySessions = 
  await _firebaseService.getTodayWorkoutSessions(userId);
```

#### Get This Week's Sessions
```dart
List<Map<String, dynamic>> weekSessions = 
  await _firebaseService.getWeekWorkoutSessions(userId);
```

#### Get This Month's Sessions
```dart
List<Map<String, dynamic>> monthSessions = 
  await _firebaseService.getMonthWorkoutSessions(userId);
```

#### Get User Statistics
```dart
Map<String, dynamic> stats = 
  await _firebaseService.getUserWorkoutStats(userId);
// Returns: { totalSessions, totalReps, averageAccuracy, totalDuration }
```

#### Delete Session
```dart
bool deleted = await _firebaseService.deleteWorkoutSession(
  userId: userId,
  sessionId: sessionId,
);
```

---

## Backend MySQL Structure

### Table: `workout_sessions`
```sql
CREATE TABLE workout_sessions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  exercise VARCHAR(100) NOT NULL,
  reps INT NOT NULL,
  accuracy FLOAT NOT NULL,
  timestamp VARCHAR(50) NOT NULL,
  duration INT NOT NULL,
  feedback_points TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES user_health_profiles(userId) ON DELETE CASCADE
);
```

### Foreign Key Relationship:
```
workout_sessions.user_id → user_health_profiles.userId
```

This ensures that:
- Workout sessions are linked to user profiles
- If a user profile is deleted, their workout sessions are also deleted (CASCADE)
- The same Firebase user ID is used consistently

### API Endpoint:
```
POST /api/workout/pose-summary
```

**Request Body:**
```json
{
  "user_id": "firebase-user-uid",
  "exercise": "squat",
  "reps": 15,
  "accuracy": 0.87,
  "timestamp": "2025-10-17T14:30:00.000Z",
  "duration": 120,
  "feedback_points": ["Keep knees aligned", "Great depth"]
}
```

**Response:**
```json
{
  "success": true,
  "message": "Workout session saved successfully",
  "motivational_feedback": "Great work! Your form is improving with each workout!"
}
```

---

## Implementation Details

### Frontend Files Modified:

#### `lib/features/pose_coach/screens/pose_coach_screen.dart`
- Added `PoseFirebaseService` import and instance
- Updated `_stopWorkout()` to:
  1. Get Firebase user ID from `authProvider.firebaseUser?.uid`
  2. Save to Firebase Firestore first
  3. Send to backend API for analytics
  4. Display results to user

**Key Code:**
```dart
// Get Firebase user ID
final userId = authProvider.firebaseUser?.uid ?? '';

// Save to Firebase
await _firebaseService.saveWorkoutSession(
  userId: userId,
  session: session,
);

// Send to backend
await _apiService.sendWorkoutSummary(session.toJson());
```

### New Firebase Service:

#### `lib/features/pose_coach/services/pose_firebase_service.dart`
- Complete CRUD operations for workout sessions
- Query methods (today, week, month)
- Statistics calculation
- Automatic error handling and logging

---

## Data Consistency

### User ID Verification:
```dart
// ✅ CORRECT - Uses Firebase Auth UID
final userId = authProvider.firebaseUser?.uid ?? '';

// ❌ INCORRECT - Uses custom UserModel id (may differ)
final userId = authProvider.user?.id ?? '';
```

### Why Two Storage Systems?

#### Firebase Firestore (Primary):
- ✅ Real-time updates
- ✅ Offline support
- ✅ User-facing features (history, stats)
- ✅ Fast queries
- ✅ Automatic scaling

#### MySQL Backend (Analytics):
- ✅ AI-powered motivational feedback
- ✅ Complex analytics queries
- ✅ Cross-user aggregations
- ✅ Integration with health profiles
- ✅ RAG (Retrieval Augmented Generation) for personalized suggestions

---

## Security Rules (Firebase)

Recommended Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own workout sessions
    match /users/{userId}/workoutSessions/{sessionId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Testing Checklist

### Frontend:
- [ ] User ID correctly retrieved from Firebase Auth
- [ ] Workout session saved to Firebase Firestore
- [ ] Firebase document created at correct path
- [ ] Backend API receives correct user_id
- [ ] Both saves complete without errors
- [ ] User sees workout summary dialog

### Backend:
- [ ] Workout session inserted into MySQL
- [ ] Foreign key constraint works correctly
- [ ] User profile exists before inserting session
- [ ] AI motivational feedback generated
- [ ] Response returned to Flutter app

### Data Consistency:
- [ ] Same user_id in both systems
- [ ] Timestamp format consistent
- [ ] Session data matches in both storages
- [ ] No orphaned records

---

## Future Enhancements

### Sync Strategy:
- Add offline queue for failed saves
- Implement retry logic with exponential backoff
- Add conflict resolution for concurrent updates

### Analytics Dashboard:
- Query Firebase for user-specific stats
- Use backend for population-level insights
- Combine data for comprehensive reports

### Data Migration:
- If needed, create script to sync Firebase → MySQL
- Or vice versa for data recovery

---

## Error Handling

### Firebase Save Fails:
- User is notified but workout still recorded locally
- Backend save proceeds independently
- Error logged for debugging

### Backend Save Fails:
- Firebase data remains intact (primary source)
- User can still view their history
- AI feedback defaults to generic message

---

## Code References

### Key Files:
1. `lib/features/pose_coach/services/pose_firebase_service.dart` - Firebase operations
2. `lib/features/pose_coach/screens/pose_coach_screen.dart` - Integration point
3. `app/routes/workout_routes.py` - Backend API endpoint
4. `app/core/db.py` - MySQL schema definition
5. `app/services/workout_service.py` - Backend database operations

### Related Services:
- `lib/services/api_service.dart` - HTTP client
- `lib/features/authentication/providers/authentication_provider.dart` - User management
- `app/models/pose_session.py` - Backend data models

---

## Summary

✅ **Single Source of Truth for User ID:** Firebase Authentication UID  
✅ **Dual Storage:** Firebase Firestore (primary) + MySQL (analytics)  
✅ **Consistent Data:** Same user_id used across all systems  
✅ **Resilient:** Independent save operations with fallbacks  
✅ **Scalable:** Both storage systems handle growth well  

The architecture ensures that:
1. User data is always accessible (Firebase)
2. AI features work seamlessly (MySQL + LangChain)
3. No data inconsistencies due to shared user ID
4. Graceful degradation if either system fails

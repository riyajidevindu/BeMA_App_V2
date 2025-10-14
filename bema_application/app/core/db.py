import mysql.connector
from mysql.connector import errorcode
from models.suggestion import Suggestion
from models.user_health import UserHealthProfile
import os
from dotenv import load_dotenv

load_dotenv()
# --- ⚙️ Database Configuration ---
# In a real application, load these from a .env file or other config management.
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', ''),
}
DB_NAME = os.getenv('DB_NAME', 'bema_db') # The name of the database to create and use

# --- SQL Table Definitions ---
# Using "CREATE TABLE IF NOT EXISTS" ensures this runs only once.
# Tables are ordered to respect foreign key dependencies.
TABLES = {}

TABLES['user_health_profiles'] = (
    "CREATE TABLE IF NOT EXISTS `user_health_profiles` ("
    "  `userId` VARCHAR(255) NOT NULL,"
    "  `age` INT NOT NULL,"
    "  `gender` VARCHAR(50) NOT NULL,"
    "  `height` FLOAT NOT NULL,"
    "  `heightUnit` VARCHAR(10) NOT NULL,"
    "  `weight` FLOAT NOT NULL,"
    "  `weightUnit` VARCHAR(10) NOT NULL,"
    "  `profession` VARCHAR(255) NOT NULL,"
    "  `smokes` BOOLEAN NOT NULL,"
    "  `smokingFrequency` VARCHAR(100) NULL,"
    "  `drinks` BOOLEAN NOT NULL,"
    "  `glassesPerWeek` VARCHAR(100) NULL,"
    "  `exercises` BOOLEAN NOT NULL,"
    "  `favoriteExercise` VARCHAR(255) NULL,"
    "  `hasDisabilitiesOrSpecialNeeds` BOOLEAN NOT NULL,"
    "  `disabilityDiscription` TEXT NULL,"
    "  `hasAllergies` BOOLEAN NOT NULL,"
    "  `allergyType` VARCHAR(255) NULL,"
    "  `hadSurgeries` BOOLEAN NOT NULL,"
    "  `surgeryType` VARCHAR(255) NULL,"
    "  `surgeryYear` INT NULL,"
    "  `hasHighBloodPressure` BOOLEAN NOT NULL,"
    "  `highBloodPressureTreatmentYears` INT NULL,"
    "  `hasDiabetes` BOOLEAN NOT NULL,"
    "  `diabetesTreatmentYears` INT NULL,"
    "  `hasCholesterol` BOOLEAN NOT NULL,"
    "  `cholesterolTreatmentYears` INT NULL,"
    "  `hasFamilyMedicalHistory` BOOLEAN NOT NULL,"
    "  `familyMedicalHistoryDiscription` TEXT NULL,"
    "  `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
    "  PRIMARY KEY (`userId`)"
    ") ENGINE=InnoDB"
)

TABLES['suggestion_items'] = (
    "CREATE TABLE IF NOT EXISTS `suggestion_items` ("
    "  `id` INT AUTO_INCREMENT NOT NULL,"
    "  `suggestionKey` VARCHAR(255) NOT NULL,"
    "  `title` VARCHAR(255) NOT NULL,"
    "  `detail` TEXT NOT NULL,"
    "  `total` INT NULL,"
    "  PRIMARY KEY (`id`)"
    ") ENGINE=InnoDB"
)

TABLES['user_suggestions'] = (
    "CREATE TABLE IF NOT EXISTS `user_suggestions` ("
    "  `id` INT AUTO_INCREMENT NOT NULL,"
    "  `userId` VARCHAR(255) NOT NULL,"
    "  `suggestionItemId` INT NOT NULL,"
    "  `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
    "  PRIMARY KEY (`id`),"
    "  FOREIGN KEY (`userId`) REFERENCES `user_health_profiles`(`userId`) ON DELETE CASCADE,"
    "  FOREIGN KEY (`suggestionItemId`) REFERENCES `suggestion_items`(`id`) ON DELETE CASCADE"
    ") ENGINE=InnoDB"
)


def store_user_health_profile(profile: UserHealthProfile):
    """Stores or updates a UserHealthProfile in the database."""
    db_conn = get_db_connection(DB_CONFIG)
    if not db_conn:
        return False

    cursor = db_conn.cursor()
    add_profile = (
        "REPLACE INTO user_health_profiles "
        "(userId, age, gender, height, heightUnit, weight, weightUnit, profession, "
        "smokes, smokingFrequency, drinks, glassesPerWeek, exercises, favoriteExercise, "
        "hasDisabilitiesOrSpecialNeeds, disabilityDiscription, hasAllergies, allergyType, "
        "hadSurgeries, surgeryType, surgeryYear, hasHighBloodPressure, highBloodPressureTreatmentYears, "
        "hasDiabetes, diabetesTreatmentYears, hasCholesterol, cholesterolTreatmentYears, "
        "hasFamilyMedicalHistory, familyMedicalHistoryDiscription) "
        "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
    )
    
    profile_data = (
        profile.userId, profile.age, profile.gender, profile.height, profile.heightUnit,
        profile.weight, profile.weightUnit, profile.profession, profile.smokes,
        profile.smokingFrequency, profile.drinks, profile.glassesPerWeek, profile.exercises,
        profile.favoriteExercise, profile.hasDisabilitiesOrSpecialNeeds, profile.disabilityDiscription,
        profile.hasAllergies, profile.allergyType, profile.hadSurgeries, profile.surgeryType,
        profile.surgeryYear, profile.hasHighBloodPressure, profile.highBloodPressureTreatmentYears,
        profile.hasDiabetes, profile.diabetesTreatmentYears, profile.hasCholesterol,
        profile.cholesterolTreatmentYears, profile.hasFamilyMedicalHistory,
        profile.familyMedicalHistoryDiscription
    )

    try:
        cursor.execute(add_profile, profile_data)
        db_conn.commit()
        print(f"✅ Successfully stored/updated profile for user: {profile.userId}")
        return True
    except mysql.connector.Error as err:
        print(f"❌ Failed to store profile for user {profile.userId}: {err}")
        db_conn.rollback()
        return False
    finally:
        cursor.close()
        db_conn.close()


def store_user_suggestions_with_suggestionItems(userId: str, suggestions: Suggestion):
    """
    Stores each suggestion item from the Suggestion object into the database
    and links them to the specified user.
    """
    db_conn = get_db_connection(DB_CONFIG)
    if not db_conn:
        return False
    
    cursor = db_conn.cursor()
    
    try:
        suggestion_data = suggestions.model_dump()

        for suggestion_key, item_details in suggestion_data.items():
            # 1. Insert the suggestion item's details into the 'suggestion_items' table
            add_item_query = (
                "INSERT INTO suggestion_items (suggestionKey, title, detail, total) "
                "VALUES (%s, %s, %s, %s)"
            )
            cursor.execute(add_item_query, (
                suggestion_key,
                item_details['title'],
                item_details['detail'],
                item_details.get('total') # Use .get() for optional fields
            ))
            
            # 2. Get the ID of the newly created suggestion item
            suggestion_item_id = cursor.lastrowid
            
            # 3. Link the user to this new suggestion item in the 'user_suggestions' table
            add_user_link_query = (
                "INSERT INTO user_suggestions (userId, suggestionItemId) "
                "VALUES (%s, %s)"
            )
            cursor.execute(add_user_link_query, (userId, suggestion_item_id))
            print(f"  -> Linked suggestion '{suggestion_key}' (ID: {suggestion_item_id}) to user {userId}")

        db_conn.commit()
        print(f"✅ Successfully stored all suggestions for user: {userId}")
        return True

    except mysql.connector.Error as err:
        print(f"❌ Database error during suggestion storage for user {userId}: {err}")
        db_conn.rollback()
        return False
    finally:
        cursor.close()
        db_conn.close()


def get_db_connection(config, with_database=True):
    """Establishes a connection to the MySQL server."""
    try:
        db_config = config.copy()
        if with_database:
            db_config['database'] = DB_NAME
        
        db_conn = mysql.connector.connect(**db_config)
        return db_conn
    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
            print("❌ Something is wrong with your user name or password")
        elif err.errno == errorcode.ER_BAD_DB_ERROR:
            print(f"❌ Database '{DB_NAME}' does not exist")
        else:
            print(f"❌ An error occurred: {err}")
        return None

def initialize_database():
    """
    Creates the database and tables if they don't exist.
    This function is designed to be run once at application startup.
    """
    print("--- 🚀 Initializing Database ---")
    db_conn = get_db_connection(DB_CONFIG, with_database=False)
    if not db_conn:
        return

    cursor = db_conn.cursor()
    try:
        cursor.execute(f"CREATE DATABASE IF NOT EXISTS `{DB_NAME}` DEFAULT CHARACTER SET 'utf8'")
        print(f"✅ Database '{DB_NAME}' checked/created successfully.")
    except mysql.connector.Error as err:
        print(f"❌ Failed to create database: {err}")
        exit(1)
    finally:
        cursor.close()
        db_conn.close()

    # Connect to the specific database to create the tables
    db_conn = get_db_connection(DB_CONFIG)
    if not db_conn:
        return
        
    cursor = db_conn.cursor()
    try:
        # Since Python 3.7+, dicts maintain insertion order. This loop will now
        # create tables in the correct order as defined in the TABLES dictionary.
        for table_name, table_description in TABLES.items():
            print(f"Checking/Creating table `{table_name}`...", end='')
            cursor.execute(table_description)
            print(" ✅")
    except mysql.connector.Error as err:
        print(f"\n❌ Failed creating tables: {err}")
    finally:
        print("--- 🎉 Database initialization complete! ---")
        cursor.close()
        db_conn.close()

# To run this script directly for setup:
if __name__ == "__main__":
    initialize_database()


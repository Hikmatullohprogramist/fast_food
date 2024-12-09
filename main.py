import zipfile

# Function to attempt unlocking the zip file with the provided password
def extract_zip(zip_file, password):
    try:
        zip_file.extractall(pwd=password.encode('utf-8'))
        print(f"Success! The password is: {password}")
        return True
    except:
        return False

def zip_password_cracker(zip_filepath, wordlist_filepath):
    # Open the zip file
    zip_file = zipfile.ZipFile(zip_filepath)
    
    # Open and read the wordlist file
    with open(wordlist_filepath, 'r') as wordlist:
        for word in wordlist:
            password = word.strip()  # Remove any surrounding whitespaces/newlines
            print(f"Trying password: {password}")
            if extract_zip(zip_file, password):
                break
        else:
            print("Password not found.")

# Example usage
zip_filepath = '/Users/hikmatillomadaliyev/Downloads/WEB200_OSWA_Foundational_Web_Application_Assessments_with_Kali_Linux'  # Path to the zip file
wordlist_filepath = 'wordlist.txt'  # Path to your password wordlist file

zip_password_cracker(zip_filepath, wordlist_filepath)

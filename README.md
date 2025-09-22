
# 🚀 Description

This script helps organize files by comparing the contents of an initial "miscellaneous" folder against a designated "main" folder. 

Any files that are already present in the main folder are identified and moved into a separate "bin" folder, while files that are unique (not found in the main folder) remain in the initial "miscellaneous" folder, in order to be manually moved and/or archived. 

This ensures that only non-duplicate files are preserved for further organizing, while duplicates are safely set aside.
 
## 📦 Installation

In order to install this program in your computer you must do the following:
- Move the program file wherever you want it to reside, eg inside "your program files" folder
- Run Powershell "as administrator"
- Inside Powershell run this command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
- You can now double click the file and run it
 
## 🧰 Notes

The script generates a hash for each file, so it does not compare based on name, modification date, or anything else. 
It does not delete any files; it simply moves them elsewhere while preserving the original path, so you can restore the initial state with a copy.
It creates a log file in the folder where it is executed.

Also available in Greek [Οδηγίες](docs/el/README_el.md)

# 💸 Support Me

If you liked the project and want to support me:

<a href='https://ko-fi.com/E1E01KVQEY' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
 
# 📄 License
This project is available under the MIT License. See the LICENSE file for more information.

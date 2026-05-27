# Workflow

For Pareto page sizes to reduce OneDrive use on shared notebooks
.one files  →  JSON (via 1note2json.py)  →  Json_page_summary.py
 
	1. Put all of my tools (python scripts, PowerShell Scripts, and ONE folder) into a working directory
	2. Either copying local notebooks, or exporting online notebooks to their own subdirectory in my tools
	3. I created batch PowerShell scripts to mass convert each subdirectories .one files (one for each section) into its own JSON subdirectory
	4. Run the size summary file to understand which pages in my online notebook were taking up the most OneDrive quota

.one files  →  JSON (via 1note2json.py)  →  Json_title_size_compare_Batch_newline.ps1  →   Json_title_size_compare.py  →  comparison report (CSV)

	1. Put all of my tools (python scripts, PowerShell Scripts, and ONE folder) into a working directory
	2. Either copying local notebooks, or exporting online notebooks to their own subdirectory in my tools
	3. I created batch PowerShell scripts to mass convert each subdirectories .one files (one for each section) into its own JSON subdirectory
	4. For Online notebooks, I also ran the size summary file to understand which pages in my online notebook were taking up the most OneDrive quota
	5. Use the PowerShell compare script to bach compare all the JSON files in two directories and save them to a csv file
	6. Picked the notebook that was the most complete and then made that a master copy.  
	7. For each local copy, I manually loaded the master copy and used OneNote to compare the master with the local using the csv summary as a guide.  I moved any updates that are not in the master to the master.
	8. I then compared the notebook with the next fewest updates that were not in the master
	9. Once my master local copy had all updates from all the out of sync local copies, I moved the existing local copies to backups and replaced them all with the master.
	
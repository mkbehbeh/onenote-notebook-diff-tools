# OneNote Notebook Diff Tools                                                                                                                                         
                                                                                                                                                                  
A set of Python and PowerShell tools for comparing Microsoft OneNote notebook                                                                                         
sections across machines — useful when migrating notebooks, recovering from                                                                                           
corruption, or verifying that a backup is complete.                        

## The Problem  
                                                                                                                                                                        
  When you have OneNote notebooks on multiple computers (or backups), there is no
  built-in way to tell whether they match. Pages can be missing, silently                                                                                               
  truncated, or have the same title but different content. These tools let you
  compare two sets of notebooks at the page level and produce a plain CSV report                                                                                        
  of every difference.  

# Background/Credits
The origin of this project was to try to identify which pages were causing OneNote 2013 to crash.  I then expanded it to estimate sizes for my online OneNote notebooks so that I could move large pages that are not actively being worked on from multiple computers to local notebooks.  (I have the free OneDrive tier with only 5GB of storage).  Finally I added comparison tools to match my local OneNote notebooks


This project builds upon the excellent work from the original
1note2json / OneNote parser project by Alexandre Grigoriev.

Original repository:
https://github.com/alegrigoriev/onenote2xml

      
# How it works                        
                                                                                                                                                                        
  Built on top of the excellent [py1note](https://github.com/alegrigoriev/onenote2xml)                                                                                         
  parser by Alexandre Grigoriev, which does the heavy lifting of reading the                                                                                            
  binary `.one` file format.                                                                                                                                            
                                                                                                                                                                        
This repository adds:
- corruption recovery workflows
	The original single line:                       
    pages[str(gosid)] = object_space_ctx.MakeRootJsonTree()
    was replaced with a try/except that catches any exception per page, prints OK PAGE or FAILED PAGE with the error, and continues to the next page instead of crashing.  
	This successfully flagged several corrupted pages which I was able to copy to new page and delete the corrupted one

- notebook comparison utilities
- semantic page fingerprinting
	As I moved more content to local notebooks, I wanted to sync all of my local notebooks.  I discovered that many of the local notebooks were out of sync and not just updates, so I developed comparison tools that would compare notebooks across machines
	
	This is much harder than it sounds because microsoft creates its own unique structure for each OneNote notebook
		○ GUIDs 
		○ Object IDs 
		○ NotebookManagementEntityGuid 
		○ Revision IDs 
		○ Position IDs 
		○ Internal child node IDs 
		All of these unique ID's make traditional file compare useless.  Instead I use a multi-step process that extracts the text, normalize it and creates a hash and character count.

	Unfortunately, trying to automatically match the notebooks will almost certainly corrupt the notebook, but flagging the mismatched pages is still very useful to narrow down where you need to manually compare the pages

- batch conversion tooling
- PowerShell automation
	For safety, I always make a local copy of my .one drives for comparison.  I developed Automated scripts to batch compare entire directories

- CSV reporting
	In my case, I had multiple notebooks that were out of sync.  Outputting the compare into excel made it easy to narrow down which pages I needed to manually check using OneNote



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
	
                                                                                                                            


## Prerequisites                                                                                                                                                      
                  
  - Python 3.9 or later
  - PowerShell 5.1 or later (Windows, or PowerShell 7+ cross-platform)
  - The `ONE/` package directory from py1note — must sit alongside `1note2json.py`                                                                                      
    in the `tools/` folder (see Setup below)                                                                                                                            
                                                                                                                                                                        
## Setup                                                                                                                                                              
                                                                                                                                                                        
  1. Clone this repository:
     git clone https://github.com/mkbehbeh/OneNote-Notebook-Diff-Tools.git
     cd OneNote-Notebook-Diff-Tools                                                                                                                                     
   2. copy the PowerShell Scripts into the tool directory
                                                                                                    
  Your `tools/` folder should look like:                                                                                                                                
     tools/                                                                                                                                                             
     ├── 1note2json.py
     ├── Json_title_size_compare.py     
     ├── 1note2json_batch(CommandLine).ps1           
     ├── Json_title_size_compare_Batch_newline.ps1                                                                                                                                   
                                                                                                                        
     └── ONE/                      
         ├── NOTE/                                                                                                                                                      
         ├── STORE/
         ├── JSON/                                                                                                                                                      
         └── ...
                                                                                                                                                                        
  3. No pip packages are required beyond the Python standard library.



## Tools
                                                                                                                                                                        
  ### `tools/1note2json.py`                                                                                                                                             
   
  Converts a single `.one` or `.onetoc2` OneNote file to JSON.    This is updated from the original 1note2json / OneNote parser project to add corruption checks to handle corrupt pages without crashing.                                                                                                         

```bash
  python tools/1note2json.py <file.one> --output <output.json>                                                                                                          
```   
   
  Key options:                                                                                                                                                          
                                                                                                                                                                        
  | Option | Short | Description |
  |--------|-------|-------------|                                                                                                                                      
  | `--output <file>` | `-O` | Output JSON filename |
  | `--output-directory <dir>` | `-R` | Write one JSON file per page into a directory |                                                                                 
  | `--all-revisions` | `-A` | Include all page revisions, not just the latest |                                                                                        
  | `--list-revisions` | `-l` | Print all revision timestamps to stdout |                                                                                               
  | `--combine-revisions <min>` | `-c` | Merge edits within N minutes into one revision |                                                                               
  | `--verbose <0-5>` | `-v` | Output verbosity level (default 0) |                                                                                                     
  | `--log <file>` | `-L` | Write parser diagnostics to a log file |                                                                                                    
                                                                                                                                                                        
                                                                                                            
  > `original_licenses/1note2json_LICENSE.txt` for its Apache 2.0 license.                                                                                              
                                                                                                                                                                        
  ---             
### `tools/Json_page_summary.py`                                                                                                                                      
                                                                                                                                                                        
  Summarizes all pages in a single JSON file, listing each page's title, date,                                                                                          
  and text size. Useful for identifying your largest pages when managing OneDrive
  storage quota — sort by size to find what to move to a local notebook.                                                                                                
                                                                                                                                                                        
```bash                                                                                                                                                               
  python tools/Json_page_summary.py <file.json>                                                                                                                         
  python tools/Json_page_summary.py <file.json> output.csv                                                                                                              
```                                                                                                                                                                     
  If no CSV path is given, output is printed to the console. If a CSV path is
  provided, the file is written and a row count is printed to the terminal.                                                                                             
                                                                                                                                                                        
  Output columns:                                                                                                                                                       
                                                                                                                                                                        
  ┌─────────────────┬──────────────────────────────────────────────────────────────────────────┐
  │     Column      │                               Description                                │
  ├─────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ Page Name       │ Page title extracted from the JSON                                       │
  ├─────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ Title Date/Time │ Date stamp from the page title bar, normalized to YYYY-MM-DD HH:MM AM/PM │                                                                        
  ├─────────────────┼──────────────────────────────────────────────────────────────────────────┤                                                                        
  │ Size (chars)    │ Total character count of all text content on the page                    │                                                                        
  └─────────────────┴──────────────────────────────────────────────────────────────────────────┘                                                                        
                  
  Sizes are shown as k for thousands (e.g. 12.3k). Pages with no                                                                                                        
  recoverable title are listed as UNKNOWN.
                                                                                                                                                                        
  ---                                                                                                                                                                               
                  
  Two notes:
                                                                                                                                                                        
  1. The date extraction (`Title Date/Time`) reads the OneNote title-bar date stamp, not the last-modified date from the file metadata. If a page has no title date,
  that column will be blank.                                                                                                                                            
                            
  2. This tool operates on one JSON file at a time (one notebook section). To summarize an entire notebook, run it once per section and combine the CSVs in Excel.  



                                                                                                                                                                        
### `tools/Json_title_size_compare.py`                                                                                                                                
   
  Compares two JSON files produced by `1note2json.py` and reports differences at                                                                                        
  the page level. 
```bash
  python tools/Json_title_size_compare.py fileA.json fileB.json                                                                                                         
```   
   
  Output sections:                                                                                                                                                      
  - **Pages in Dir 1 only** — pages present in the first file but not the second
  - **Pages in Dir 2 only** — pages present in the second file but not the first                                                                                        
  - **Same title, different content** — pages with matching titles but different                                                                                        
    text content, with character counts and which copy is larger                                                                                                        
  - **Summary** — total page count and character volume for each file                                                                                                   
                                                                                                                                                                        
  Comparison is done by MD5 fingerprint of normalized page text, so formatting                                                                                          
  changes that don't alter content are ignored.                                                                                                                         
                                                                                                                                                                        
  ---             

### `powershell/1note2json_batch(CommandLine).ps1`                                                                                                                    
   
  Batch-converts a folder of `.one` files to JSON. Skips files that have already                                                                                        
  been converted. 
                                                                                                                                                                        
```powershell   
  .\powershell\1note2json_batch(CommandLine).ps1 `
      -InputDir  "C:\MyNotebooks" `
      -OutputDir "C:\MyNotebooks\JSON"                                                                                                                                  
```   
  Parameters:                                                                                                                                                           
                  
  ┌────────────┬──────────┬───────────────────────────────────────────────────────────────┐                                                                             
  │ Parameter  │ Required │                          Description                          │
  ├────────────┼──────────┼───────────────────────────────────────────────────────────────┤                                                                             
  │ -InputDir  │ Yes      │ Folder containing .one source files                           │
  ├────────────┼──────────┼───────────────────────────────────────────────────────────────┤
  │ -OutputDir │ Yes      │ Folder where JSON output files are saved (created if missing) │                                                                             
  └────────────┴──────────┴───────────────────────────────────────────────────────────────┘                                                                             
                                                                                                                                                                        
  1note2json.py and its ONE/ package must be in the same directory as this                                                                                              
  script, or you must adjust $pythonScriptPath at the top.
                                                                                                                                                                        
  ---             
### powershell/Json_title_size_compare_Batch(CommandLine).ps1                                                                                                             
                                                                                                                                                                        
  Orchestrates comparisons across two entire directories of JSON files and writes
  a consolidated CSV report.                                                                                                                                            

```PowerShell                  
  .\powershell\Json_title_size_compare_Batch(CommandLine).ps1 `                                                                                                         
      -JsonDir1   "C:\Notebooks\Machine1\JSON" `
      -JsonDir2   "C:\Notebooks\Machine2\JSON" `                                                                                                                        
      -CsvOutput  "C:\Reports\comparison.csv"                                                                                                                           
```                                                                                                                                                                        
  Parameters:                                                                                                                                                           
                  
  ┌────────────┬──────────┬────────────────────────────────────────────────────┐
  │ Parameter  │ Required │                    Description                     │
  ├────────────┼──────────┼────────────────────────────────────────────────────┤
  │ -JsonDir1  │ Yes      │ First set of JSON files (your baseline)            │
  ├────────────┼──────────┼────────────────────────────────────────────────────┤
  │ -JsonDir2  │ Yes      │ Second set of JSON files (what you're checking)    │                                                                                        
  ├────────────┼──────────┼────────────────────────────────────────────────────┤                                                                                        
  │ -CsvOutput │ No       │ Output CSV path (default: .\Comparison_Report.csv) │                                                                                        
  └────────────┴──────────┴────────────────────────────────────────────────────┘                                                                                        
                  
  The CSV has three columns:                                                                                                                                            
                  
  ┌────────────────────┬───────────────────────────────────────────────────────┐
  │       Column       │                        Values                         │
  ├────────────────────┼───────────────────────────────────────────────────────┤
  │ SectionFile        │ The .json filename (one row per discrepancy)          │
  ├────────────────────┼───────────────────────────────────────────────────────┤
  │ Status             │ Identical, Page Mismatch Found, or Mismatched Section │                                                                                        
  ├────────────────────┼───────────────────────────────────────────────────────┤                                                                                        
  │ DiscrepancyDetails │ Description of the difference, with size info         │                                                                                        
  └────────────────────┴───────────────────────────────────────────────────────┘                                                                                        
                  
  ---                                                                                                                                                                   
 
###powershell/1note2json_batch.ps1 and Json_title_size_compare_Batch_newline.ps1
                                                                                                                                                           
  Simpler hardcoded variants of the above scripts with paths baked in. Useful as
  a starting point if you prefer to edit paths directly rather than pass                                                                                                
  parameters. Copy one, update the directory variables at the top, and run.       



## Typical Workflow                                                                                                                                                      
                                                                                                                                                                        
  Step 1 — Export your notebooks from OneNote                                                                                                                           
                  
  If a .one file fails to parse with Attempted read of N bytes with only 0 bytes remaining, re-export the section from OneNote (File → Export → Section                 
  → .one format). The re-export produces a clean, well-formed file.
                                                                                                                                                                        
  Step 2 — Convert both sets to JSON                                                                                                                                    
                                                                                                                                                                        
```powershell
# Machine 1 notebooks                                                                                                                                                 
  .\powershell\1note2json_batch(CommandLine).ps1 `                                                                                                                      
      -InputDir  "C:\Backup\Machine1" `
      -OutputDir "C:\Backup\Machine1\JSON"                                                                                                                              
                                                                                                                                                                        
# Machine 2 notebooks
  .\powershell\1note2json_batch(CommandLine).ps1 `                                                                                                                      
      -InputDir  "C:\Backup\Machine2" `
      -OutputDir "C:\Backup\Machine2\JSON"                                                                                                                              
```   
  
  Step 3 — Compare                                                                                                                                                      
```powershell                
  .\powershell\Json_title_size_compare_Batch(CommandLine).ps1 `
      -JsonDir1  "C:\Backup\Machine1\JSON" `                                                                                                                            
      -JsonDir2  "C:\Backup\Machine2\JSON" `
      -CsvOutput "C:\Reports\diff.csv"                                                                                                                                  
```                                                                                                                                                                        
  Step 4 — Review the CSV
                                                                                                                                                                        
  Open diff.csv in Excel. Filter the Status column for Page Mismatch Found                                                                                              
  and Mismatched Section to see only the differences. The DiscrepancyDetails
  column shows the page title, size on each side, and which copy is larger.                                                                                             
                                                                                                                                                                        
## Limitations                                                                                                                                                           
                                                                                                                                                                        
  - Comparison is text-content only. Images, drawings, and embedded files are not                                                                                       
  included in the fingerprint or size count.
  - Page order within a section is not compared — only presence and content.                                                                                            
  - The tools work on .one section files, not .onetoc2 notebook table-of-                                                                                               
  contents files (for batch conversion).                                                                           

## LICENSE
  The tools in this repository (Json_title_size_compare.py and the PowerShell                                                                                           
  scripts) are released under the MIT License — see LICENSE.
                                                                                                                                                                        
  tools/1note2json.py is a modified copy from the py1note project by
  Alexandre Grigoriev and is licensed under the Apache License 2.0 — see                                                                                                
  original_licenses/1note2json_LICENSE.txt.       
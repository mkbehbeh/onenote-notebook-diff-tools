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

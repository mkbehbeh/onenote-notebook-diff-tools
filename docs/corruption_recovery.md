  # Corruption Recovery                                                                                                                                                 
                                                                                                                                                                        
  The original `1note2json.py` would crash on the first corrupted page it encountered,                                                                                  
  making the entire section unprocessable.
                                                                                                                                                                        
  `tools/ONE/JSON/json_tree_builder.py` wraps each page parse in a try/except block.                                                                                    
  On success it prints `OK PAGE: <guid>`. On failure it prints `FAILED PAGE: <guid>`                                                                                    
  with the error message and continues to the next page.                                                                                                                
                                                                                                                                                                        
  This allows a corrupted section to be partially converted — all intact pages are                                                                                      
  saved to JSON, and the failed page GUIDs are logged for manual inspection in OneNote.
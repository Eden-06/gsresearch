Workflow
========

Contains a set of shell scripts and describes a workflow to conduct a
semi-automatic survey by employing **gsresearch**, **bibfilter**, and **gsdownload**.

Preparation
------------

1. Create a new empty folder for your survey
2. Copy the following files from gsresearch and bibfilter to this folder
    * gsresearch.rb (including the modules *-module.rb) 
    * gsdownload.rb (including the modules gsdownload-modules.rb)
    * bibfilter.rb
    * autofilter.sh
    * gsdownload.sh
    * gsresearch.sh
    * relevancefilter.sh
3. Change the **gsresearch.sh** to reflect your search query and the range of years you are interested in.
4. Modify the Constant factor in the **relevancefilter.sh** to a suitable value (you can adapt this value later on)

Execution
---------
1. Execute the **gsresearch.sh** from within your survey folder.
2. Be patient
3. Be very patient
4. Look at the error log in your command prompt and rerun all years
	where a timeout occured.
  (Note: You can simply adapt the time range in the gsresearch script
5. Run the **autofilter.sh** script
6. Check if the number of relevant (filter_rel) publications fits your needs  
	If not just adjust the Constant within the relevancefilter.sh script redo step 5.
7. Create a filter_human/ folder in your survey folder
8. You guessed it, now you must manually go through the publications and
  sort the wheat from the chaff. To do this use the interactive mode of **bibfilter**.
```bash
  $> for f in `ls filter_rel/` ; do echo $f ; ruby bibfilter.rb "filter_rel/$f" > "filter_human/$f" ; done
```
9. Now you can run the **gsdownload.sh** script to download all publications
  you have selected previously to the downloads folder
10. Afterwards, you can go through the bibtex items in the download filter and mark all relevant approaches
  with `comment = {ApproachTag}`. Approach tags must be words without whitespaces.
11. Then you can create the approaches folder with `mkdir approaches`
12. Finally, you can rerun **autofilter.sh** to get the statistics for the various filter steps.
    (Make sure that the APPROACHES variable collects in the script all approach tags separated by a whitespace.)

Disclaimer
---------- 
Please note that you should not use this script in jurisdictions,
where automated use of publishers is prohibited (almost everywhere).
Please read the respective Terms of Service of the various publishers,
including Google, Springer, ACM, IEEE and ScienceDirect for more information.

Limitations
-----------

* You manually have to change the **gsresearch.sh** script.
* The **gsresearch.sh** script is designed to continue work after recieving an error
* Mechanizes file download some how does not support utf-8 character encoding, sadly all bibtex files are encoded as ASCII-8Bit (hopefully this issue might be fixed soon).

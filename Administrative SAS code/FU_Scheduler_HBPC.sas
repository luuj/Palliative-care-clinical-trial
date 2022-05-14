/*What this file does:
Reads in ID, date of baseline, and study completion and determines 1-month and 2-month follow up times
Dataset is exported from Follow Up Appointments*/
%LET directory = C:\Users\jluu\Dropbox\Research\Mack\RedCap SAS Files\Follow-up Scheduler;
%LET date = %sysfunc(today(),mmddyy7.);

/*****Import in dataset*****/
proc import datafile="&directory\ExpandingAccessToHom_DATA_2018-09-14_1148.csv" out=mydata dbms=csv replace; 
	getnames=yes; 
run;

/*****Create window and target dates for currently enrolled subjects*****/
%macro scheduler(type, FU_num);
data &type&FU_num;
	set mydata(rename=(bl_complete=bl_complete_pt));

	/*Retrieve appropriate variables from the dataset*/
	if ("&type" = "pt" and redcap_event_name ^= "admin_arm_1") then delete; 
	if ("&type" = "cg" and redcap_event_name ^= "admin_arm_2") then delete; 
	
	Visit_type = "&FU_num";
	if Visit_type = "FU1" then do;
		/*Create appropriate FU1 windows and target dates*/
		Date_open = intnx('day',bl_complete_&type,23);
		Date_close = intnx('day',bl_complete_&type,37);
		Target_date = intnx('day',bl_complete_&type,28);
	end;	
	else do;
		/*Create appropriate FU2 windows and target dates*/
		Date_open = intnx('day',bl_complete_&type,53);
		Date_close = intnx('day',bl_complete_&type,67);
		Target_date = intnx('day',bl_complete_&type,58);
	end;

	format bl_complete_pt bl_complete_cg Date_open Date_close Target_date mmddyy.;
	label pid="ID" bl_complete_pt="Baseline Date" bl_complete_cg="Baseline Date";
run; 
%mend scheduler;

%scheduler(pt, FU1);
%scheduler(pt, FU2);
%scheduler(cg, FU1);
%scheduler(cg, FU2);


/*****Combine the patient datasets, check date range, and export*****/
data combined;
	/*Combine and reorder variables*/
	retain pid Visit_type;
	set ptFU1 ptFU2 cgFU1 cgFU2;

	if Date_open < today()-13 or Date_open > (today()+14) then delete;
	drop bl_complete_pt bl_complete_cg redcap_repeat_instrument redcap_repeat_instance; 

	/*Export*/
	proc export data=combined dbms=xlsx outfile="&directory\HBPC_FUSchedule_&date." replace label;
run;





/*What this file does:
Exports list of patients whose 11th day since their referral date is coming up in the next week - filtered by empty screening status
Dataset is exported from Unable to Contact*/
%LET directory = C:\Users\jluu\Dropbox\Research\Mack\RedCap SAS Files\Unable To Contact Scheduler;
%LET date = %sysfunc(today(),mmddyy7.);

/*****Import in dataset*****/
proc import datafile="&directory\ExpandingAccessToHom_DATA_2018-09-14_1315.csv" out=mydata dbms=csv replace; 
	getnames=yes; 
run;

data utc_scheduler;
	set mydata (drop=redcap_repeat_instrument redcap_repeat_instance);

	final_date = intnx('day',refdate,11);
	format refdate final_date mmddyy.;

	if final_date > today()+7 or final_date < today() then delete;
	proc export data=utc_scheduler dbms=xlsx outfile="&directory\HBPC_UTCSchedule_&date." replace label;
run;


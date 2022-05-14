/*What this file does:
Reads in ID and contact log appointment date/time. Exports schedule for the next two weeks of upcoming 
appointments or the previous two weeks of missed appointment
Dataset is exported from Contact Log Appointments*/
%LET directory = C:\Users\jluu\Dropbox\Research\Mack\RedCap SAS Files\Contact Log Scheduler;
%LET date = %sysfunc(today(),mmddyy7.);

/*****Import in dataset*****/
proc import datafile="&directory\ExpandingAccessToHom_DATA_2018-09-14_1130.csv" out=mydata dbms=csv replace; 
	getnames=yes; 
run;

/*Filter data set to get upcoming appointments for the next two weeks*/
data getUpcomingApts;
	set mydata (drop=redcap_repeat_instrument);
	
	if apptdate_con < today() or apptdate_con > today()+14 then delete;
	apt_type = "Upcoming";

	format apptdate_con mmddyy. appttime_con timeampm9.;
	label redcap_event_name="Patient/Caregiver"
		  redcap_repeat_instance="Contact Log Number"
		  apptdate_con="Appointment Date"
		  appttime_con="Appointment Time"
		  apt_type="Missed/Upcoming Appointment";
run;

/*Filter data set to get missed appointments for the previous two weeks*/
data getMissedApts;
	set mydata (drop=redcap_repeat_instrument);

	if apptdate_con >= today() or apptdate_con < today()-13 then delete;
	if new_contact_log_complete=2 then delete;
	apt_type="Missed";

	format apptdate_con mmddyy. appttime_con timeampm9.;
	label redcap_event_name="Patient/Caregiver"
		  redcap_repeat_instance="Contact Log Number"
		  apptdate_con="Appointment Date"
		  appttime_con="Appointment Time"
		  apt_type="Missed/Upcoming Appointment";

	drop new_contact_log_complete;
run;

/*Combine upcoming and missed appointments*/
data combinedApts;
	set getUpcomingApts getMissedApts;
run;

/*Separate patients and caregivers*/
proc sort data=combinedApts;
	by redcap_event_name;
run;

proc export data=combinedApts dbms=xlsx outfile="&directory\HBPC_CLSchedule_&date." replace label;
proc print data=combinedApts; run;

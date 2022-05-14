/*Import in to-be-merged dataset*/
proc import datafile="C:\Users\jluu\Dropbox\Research\Mack\RedCap SAS Files\Master Patient List\MPL_Data.csv" out=mydata dbms=csv replace; getnames=yes; 
run;

/*Import in master patient list*/
proc import datafile="D:\Master Patient Lists\MPL_Copy.xlsx" out=mpl dbms=xlsx replace; getnames=yes; 
run;

/*Formatting*/
proc format;
	value scstatus_fmt 1="Pre-screening" 2="Pre-screen failure" 3="Screening" 4="Ineligible" 5="Eligible but did not consent" 6="Consented";
	value disposition_fmt 99="Other" 1="Patient lives outside of HBPC zip coverage" 2="Death" 3="No longer with medical group/ACO" 4="Started but did not complete eligibility"
						  10="Inclusion: Current BSC member" 11="Inclusion: 18 years of age or older" 12="Inclusion: Diagnosis of HF, COPD, or advanced cancer"
						  13="Inclusion: One or more hospitalizations or ED visits in the previous year" 14="Inclusion: English- or Spanish- speaking"
						  15="Exclusion: Diagnosis of ESRD" 16="Inclusion: An AKPS score of =80%" 17="Exclusion: Lives in a nursing home"
						  18="Exclusion: Receiving hospice or home-based palliative care" 21="Not interested in participating in a study" 
						  22="Does not think it will be helpful" 23="Too sick/tired" 24="Too burdensome" 25="No time" 26="Not comfortable" 
						  27="Unwilling to provide address/email" 28="No reason provided" 29="Privacy concerns" 30="No ER/hospital stays";
run;

/*To-be-merged dataset operations*/
data reason;
	/*Drop unnecessary variables and rename ID variable for merging*/
	set mydata (drop=psfail_other ineligible_other decline_other
				rename=(screen_id=PreScreenID));
	
	/*Remove patients who we have never contacted as well as those currently in prescreening status*/
	if (reason_psfail=1 or reason_psfail=2 or reason_psfail=3 or reason_psfail=4 or reason_psfail=5 or reason_psfail=6) then delete;
	if scstatus=1 then delete;

	/*Create disposition column*/
	/*Pre-screen failures*/
	if (scstatus=2 and reason_psfail^=7) then do;
		if reason_psfail=8 then disposition=1; /*Lives outside zip coverage*/
		else if reason_psfail=11 then disposition=2; /*Death*/
		else if reason_psfail=12 then disposition=3; /*No longer with medical group*/
		else if reason_psfail=13 then disposition=4; /*Started but did not complete eligibility*/
		else if reason_psfail=99 then disposition=99; /*Other*/
	end;
	/*Ineligible*/
	else if scstatus=4 then do;
		if rsn_inelgible___0=1 then disposition=10; /*Current BSC member*/
		else if rsn_inelgible___1=1 then disposition=11; /*18 years or older*/
		else if rsn_inelgible___2=1 then disposition=12; /*HF, COPD, or cancer*/
		else if rsn_inelgible___3=1 then disposition=13; /*One or more hospitalizations/ED visits*/
		else if rsn_inelgible___4=1 then disposition=14; /*English or Spanish speaking*/
		else if rsn_inelgible___5=1 then disposition=15; /*Diagnosis of ESRD*/
		else if rsn_inelgible___6=1 then disposition=16; /*AKPS*/
		else if rsn_inelgible___7=1 then disposition=17; /*Nursing home*/
		else if rsn_inelgible___8=1 then disposition=18; /*Hospice or HBPC*/
		else if rsn_inelgible___99=1 then disposition=99; /*Other*/
	end;
	/*Decline or opt out*/
	else if (scstatus=5 or (scstatus=2 and reason_psfail=7))then do;
		if reason_decline___1=1 then disposition=21; /*Not interested*/
		else if reason_decline___2=1 then disposition=22; /*Not helpful*/
		else if reason_decline___3=1 then disposition=23; /*Too sick/tired*/
		else if reason_decline___4=1 then disposition=24; /*Burdensome*/
		else if reason_decline___5=1 then disposition=25; /*No time*/
		else if reason_decline___6=1 then disposition=26; /*Not comfortable*/
		else if reason_decline___9=1 then disposition=27; /*Unwilling to provide address/email*/
		else if reason_decline___10=1 then disposition=28; /*No reason*/
		else if reason_decline___11=1 then disposition=29; /*Privacy concerns*/
		else if reason_decline___12=1 then disposition=30; /*No ER visits/hospital stays in last year*/
		else if reason_decline___99=1 then disposition=99; /*Other*/
	end;
run;

/*Merge the two datasets*/
data merged_reason;
	merge reason mpl;
	by PreScreenID;

	/*Remove patients without a status*/
	if scstatus="." then delete;

	/*Formats and labels*/
	label scstatus="Screening status" disposition="Current disposition" PT_NAME="Patient name";
	format scstatus scstatus_fmt. disposition disposition_fmt.;
run;

/*Retrieve appropriate variables from merged_reason*/
data final;
	retain PreScreenID PT_NAME scstatus disposition;
	set merged_reason (keep=PreScreenID PT_NAME scstatus disposition);
run;

/*Export to excel*/
ods excel file="C:\Users\jluu\Dropbox\Research\Mack\RedCap SAS Files\Master Patient List\disposition_list.xlsx";
proc report data=final;
  columns _all_;
run;
ods excel close;

proc print data=final label; run;


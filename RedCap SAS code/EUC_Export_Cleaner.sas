proc import datafile="G:\EUC Referrals\ExpandingAccessToHom_DATA_2018-09-24_1116.csv" out=mydata dbms=csv replace;
	getnames=yes;
run;

proc format;
	value yesno 0="No" 1="Yes" -88="Refused" -99="Unknown";
run;

data cleaned_data;
	/*Combine rows by ID*/
	update mydata (obs=0) mydata;
	by pid;

	/*Combine ER and hospitalization columns*/
	if (ervisits NE ".") then er_visits=ervisits;
	else er_visits=er_adm_count;
	if (totalhosper NE ".") then hosp_adm=totalhosper;
	else hosp_adm=hosp_adm_count;

	/*Variable drop and rename*/
	drop redcap_event_name redcap_repeat_instrument redcap_repeat_instance ervisits totalhosper hosp_adm_count er_adm_count;
	rename phq9_total=depression acp3=advance_directive;
run;

/*Export to excel keeping formats*/
proc sql;
	create view formatted_view as
	select *, put(heart_pt, yesno.) as heart,
	put(copd_pt, yesno.) as copd,
	put(cancer_pt, yesno.) as cancer,
	put(advance_directive, yesno.) as ad from cleaned_data;
quit;

data formatted_view2;
	set formatted_view (drop=heart_pt copd_pt cancer_pt advance_directive);
run;

proc export data=formatted_view2 outfile="G:\EUC Referrals\EUC_Referrals.xlsx" dbms=xlsx replace;
run;



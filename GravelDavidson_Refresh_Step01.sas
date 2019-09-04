/* Project: GravelDavidson_Refresh */


/* Step 1: Create Reference Files (A-1) Rebuild (A-2, A-3)  */

* Table of Contents: ;
* * Action 1 (A-1): Create Data Filters;
* * Action 2: Filter Data;
* * Action 3: Rebuild Files;

/* Point to Data files; Create a folder for outputs */
libname DATA 'R:\diab_update';
libname OUTPUT 'R:\Output';


/* Action 1: Create Data Filters */
* SA 1.1: MI (MI Diagnosis IDs.csv);
* SA 1.2: antidiabetics (Master list of med IDs.csv);
* SA 1.3: insulin (Insulin med IDs.csv);
* SA 1.4: metformin1 (Metformin mono IDs.csv);
* SA 1.5: PCOS (PCOS diagnosis ID.csv);
* SA 1.6: gest_diabetes (Gestational diabetes diagnosis IDs.csv);
* SA 1.7: Ambulatory (Encounter IDs for Non-Ambulatory.csv);
* Sub-Action 1.8: table (output.pio: DATA.hf_d_medication) ;
* Sub-Action 1.9: table (output.rosi: DATA.hf_d_medication) ;

* Required Files: ;
* * MI Diagnosis IDs.csv;
* * Master list of med IDs.csv;
* * Insulin med IDs.csv;
* * Metformin mono IDs.csv;
* * Sul mono IDs.csv;
* * PCOS diagnosis ID.csv;
* * Gestational diabetes diagnosis IDs.csv;
* * Encounter IDs for Non-Ambulatory.csv;
* * DATA.hf_d_medication ;

* Output Files: ;
* * output.MI (SA 1.1);
* * output.antidiabetics (SA 1.2);
* * output.insulin (SA 1.3);
* * output.PCOS (SA 1.5);
* * output.gest_diabetes; (SA 1.6);

/* Sub-Action 1.1: */
proc import datafile = "R:\Action1_FilesForCode\MI Diagnosis IDs.csv"
out = output.MI;
run;
/* Sub-Action 1.2: */
proc import datafile = "R:\Action1_FilesForCode\Master list of med IDs.csv"
out = output.antidiabetics;
run;
/* Sub-Action 1.3: */
proc import datafile = "R:\Action1_FilesForCode\Insulin med IDs.csv"
out = output.insulin;
run;
/* Sub-Action 1.4: */
proc import datafile = "R:\Action1_FilesForCode\Metformin mono IDs.csv"
out = metformin1; * will be used in Action 2;
run;
/* Sub-Action 1.5: */
proc import datafile = "R:\Action1_FilesForCode\Sul mono IDs.csv"
out = sulfo1; * will be used in Action 2;
run;
/* Sub-Action 1.5: */
proc import datafile = "R:\Action1_FilesForCode\PCOS diagnosis ID.csv"
out = output.PCOS;
run;
/* Sub-Action 1.6: */
proc import datafile = "R:\Action1_FilesForCode\Gestational diabetes diagnosis IDs.csv"
out = output.gest_diabetes;
run;
/* Sub-Action 1.7: */ * NOT USED;
*proc import datafile = "R:\Action1_FilesForCode\Encounter IDs for Non-Ambulatory.csv";
*out = output.Ambulatory;
*run;

/* Sub-Action 1.8: table (output.pio: DATA.hf_d_medication) */
proc sql;
create table output.pio as
  select * from DATA.hf_d_medication
    where GENERIC_NAME like 'pioglitazone';
quit;

/* Sub-Action 1.9: table (output.rosi: DATA.hf_d_medication) */
proc sql;
create table output.rosi as
  select * from DATA.hf_d_medication
  where GENERIC_NAME like 'rosiglitazone';
quit;


/* Action 2: Filter Data */
* SA 2.1: output.metformin (data.hf_d_medication * metformin1);
* SA 2.2: output.sulfo (data.hf_d_medication * sulfo1);
* SA 2.3: output.CEmeds (output.metformin * output.sulfo);

* Required Files: ;
* * data.hf_d_medication;
* * metformin1 (SA 1.4);
* * sulfo1 (SA 1.5);
* * output.metformin (SA 2.1);
* * output.sulfo (SA 2.2);

* Output Files: ;
* * output.metformin (SA 2.1);
* * output.sulfo (SA 2.2);
* * output.CEmeds (SA 2.3);


/* Sub-Action 2.1: output.metformin (data.hf_d_medication * metformin1)*/
PROC SQL;
  CREATE TABLE output.metformin AS
  SELECT * FROM data.hf_d_medication
  WHERE medication_id IN (SELECT medication_id FROM metformin1);
QUIT;

/* Sub-Action 2.2: output.sulfo (data.hf_d_medication * sulfo1)*/
PROC SQL;
  CREATE TABLE output.sulfo AS
  SELECT * FROM data.hf_d_medication
  WHERE medication_id IN (SELECT medication_id FROM sulfo1);
QUIT;

/* Sub-Action 2.3: CEmeds (output.metformin * output.sulfo)
* Creates table of SKs with med IDs
*/
data output.CEmeds;
set output.metformin output.sulfo;
run;


/* Action 3: Rebuild Files */
* Sub-Action 3.1: output.rebuild_antidiab_meds (data.hf_f_medication_#,20 * antidiabetics);
* Sub-Action 3.2: output.rebuild_antidiab_enc (output.rebuild_antidiab_meds * data.hf_f_encounters_#,6);
* Sub-Action 3.3: output.rebuild_antidiab_enc_diag (output.rebuild_antidiab_enc * data.hf_f_diagnosis_#,3);

* Required Files: ;
* * data.hf_f_medication_#, 20;
* * output.antidiabetics (SA 1.2);
* * output.rebuild_antidiab_meds (SA 3.1);
* * data.hf_f_encounters_#,6 ;
* * output.rebuild_antidiab_enc (SA 3.2);
* * data.hf_f_diagnosis_#,3 ;

* Output Files: ;
* * output.rebuild_antidiab_meds (SA 3.1);
* * output.rebuild_antidiab_enc (SA 3.2);
* * output.rebuild_antidiab_enc_diag (SA 3.4);

/* Action 3.1: All encounters with an OHA */
* Create table: output.hf_f_medication_all (data.hf_f_medication * antidiabetics);

* Required Files: ;
* * data.hf_f_medication_1:20;
* * output.antidiabetics (SA 1.2);

* Output Files: ;
* * output.rebuild_antidiab_meds (SA 3.1);

%macro medloop(table,TotalTables);
PROC SQL;
%DO k=1 %TO &TotalTables;
  CREATE TABLE D&k. AS
  SELECT * FROM &table&k.
  WHERE MEDICATION_ID IN (SELECT MEDICATION_ID FROM output.antidiabetics);
%END;
QUIT;
%mend;

%medloop(DATA.hf_f_medication_,20);

data output.rebuild_antidiab_meds; ***all encounters with an OHA***;
set D1 D2 D3 D4 D5 D6 D7 D8 D9 D10 D11 D12 D13 D14 D15 D16 D17 D18 D19 D20;
run;

/* Action 3.2: All encounters with an OHA */
* Create table: output.rebuild_antidiab_enc (output.rebuild_antidiab_meds * data.hf_f_encounters_#,6);

* Required Files: ;
* * output.rebuild_antidiab_meds (SA 3.1);
* * data.hf_f_encounters_#,6 ;

* Output Files: ;
* * output.rebuild_antidiab_enc (SA 3.2);

%macro medloop(table,TotalTables);
PROC SQL;
%DO k=1 %TO &TotalTables;
  CREATE TABLE E&k. AS
  SELECT t1.encounter_id, t1.medication_id,
    int(t2.admitted_dt_tm) AS admitted_dt_tm,
    int(t2.discharged_dt_tm) AS discharged_dt_tm,
    t2.patient_id,
    t2.age_in_years,
    t2.discharge_caresetting_id,
    t2.discharge_disposition_id
  FROM output.rebuild_antidiab_meds as t1
  LEFT JOIN &table&k. as t2
  ON t1.encounter_id = t2.encounter_id;
%END;
QUIT;
%mend;

%medloop(DATA.hf_f_encounters_, 6);

data output.rebuild_antidiab_enc;
set E1 E2 E3 E4 E5 E6;
run;


/* Sub-Action 3.3: Diagnosis IDs */
* Create table: output.rebuild_antidiab_enc_diag (output.rebuild_antidiab_enc * data.hf_f_diagnosis_#,3);

* Required Files: ;
* * output.rebuild_antidiab_enc (SA 3.2);
* * data.hf_f_diagnosis_#,3 ;

* Output Files: ;
* * output.rebuild_antidiab_enc_diag (SA 3.4);

%macro medloop(table,TotalTables);
PROC SQL;
%DO k=1 %TO &TotalTables;
  CREATE TABLE G&k. AS
  SELECT t1.*, t2.*
  FROM output.rebuild_antidiab_enc as t1
  LEFT JOIN &table&k. as t2
  on t1.encounter_id = t2.encounter_id;
%END;
QUIT;
%mend;

%medloop(data.hf_f_diagnosis_, 3);

data output.rebuild_antidiab_enc_diag;
set G1 G2 G3;
run;

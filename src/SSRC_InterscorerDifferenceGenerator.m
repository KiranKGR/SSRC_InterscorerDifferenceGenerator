%% SSRC_InterscorerDifferenceGenerator
% The code generates interscorer difference given Domino Marker files of the sleep recordings and Sleep
% profile exports from two sleep experts.
% For further instructions and attribution/Citation guidelines, please visit the
% github repository, https://github.com/KiranKGR
%% License
% "SSRC_InterscorerDifferenceGenerator.m Copyright (C) 2024  Kiran K G Ravindran.
% Affiliation: University of Surrey and UK Dementia Research Institute Care
% Research and Technology Centre.
% Contact: email: k.guruswamyravindran@surrey.ac.uk
% This program is free software: you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the
% Free Software Foundation, either version 3 of the License,
% or (at your option) any later version. This program is distributed
% WITHOUT ANY WARRANTY.  See the GNU General Public License for more details
% (https://www.gnu.org/licenses/)
%%
clear; close all; clc;
warning('off','all')
%% setting path
% Add the input Folder path here
% Reach participant file set should have 'Unique_Participant_ID'
% the folder should contain one set Marker_'Unique_Participant_ID'.txt and two sets of hypnograms
% Sleep Profile - 'Unique_Participant_ID'_'Scorer1ID'.txt and
% Sleep Profile - 'Unique_Participant_ID'_'Scorer2ID'.txt
data_path = fullfile(pwd, '..\exampledata');
% creates a directory called Output_ISD_"todaysdate" 
% the interscorer difference spreadsheets go into this folder.
mkdir(pwd,"Output_"+string(datetime("today")))
directory_path=fullfile(pwd,"Output_"+string(datetime("today")));
%  Scorer 1 and 2 ids in the file
% the difference is estimated between Scorer 1 and 2
Scorer1="Scorer1";
Scorer2="Scorer2";
%%
addpath(data_path);
fprintf('Set data folder: \n');
disp(data_path);
%% Loading file
file_list=dir(strcat(data_path,'\*.txt'));
file_names=extractfield(file_list,'name')';
%
Marker_files = file_names(contains(file_names,'Marker','IgnoreCase',true));
file_names((contains(file_names,'Marker','IgnoreCase',true)))=[];
S1_files = file_names(contains(file_names,Scorer1,'IgnoreCase',true));
S2_files = file_names(contains(file_names,Scorer2,'IgnoreCase',true));
for i=1:length(Marker_files)
    disp(Marker_files{i})
    %% Hypnogram data
    % Marker
    fid = fopen(Marker_files{i});
    Marker= textscan(fid, '%s %s', 'Delimiter', ';');
    File_S1=readcell(S1_files{i},'ExpectedNumVariables',4);
    [Var_tab_S1,time_vec_S1,S1_label]=Label_Marker_ID(Marker,File_S1);
    S1_L_label=S1_label(Var_tab_S1.ind_loff:Var_tab_S1.ind_lon-Var_tab_S1.adj);
    % PSG
    File_S2=readcell(S2_files{i},'ExpectedNumVariables',4);
    [Var_tab_S2,time_vec_S2,S2_label]=Label_Marker_ID(Marker,File_S2);
    S2_L_label=S2_label(Var_tab_S2.ind_loff:Var_tab_S2.ind_lon-Var_tab_S2.adj);
    if isequal(time_vec_S1,time_vec_S2)
        time_vec_common=time_vec_S1;
        L_time_vec=time_vec_common(Var_tab_S1.ind_loff:Var_tab_S1.ind_lon-Var_tab_S1.adj);
    end
    %% difference between the hypnograms
    Diff_log=S1_label-S2_label;
    Diff_index=find(Diff_log~=0);
    Diff_index2=find(Diff_log==0);
    Num_diff=length(Diff_index);
    Num_label=length(S1_label);
    per_diff=(Num_diff/Num_label)*100;
    %
    %% Printing into a excel sheet
    Stage_label={'N3','N2','N1','REM','Wake','A'};
    Stage_num=[1 2 3 4 5 6];
    M=dictionary(Stage_num,Stage_label);
    Scorer1_label=S1_label(Diff_index);
    Scorer1_string=string(M(Scorer1_label));
    Scorer2_label=S2_label(Diff_index);
    Scorer2_string=string(M(Scorer2_label));
    time=(time_vec_common(Diff_index));
    [y,m,d] = ymd(time);
    [h,mm,s] = hms(time);
    formatOut = 'dd/mm/yyyy';
    file=S1_files{i};
    file=erase(file,' ');
    file=(erase(string(extractBetween(file,"_",".txt")),"_"+Scorer1));
    metrics_doc=strcat('Interscorer_agreement_',file,'.xls');
    Output=fullfile(directory_path,metrics_doc);
    Data=table(Diff_index,datestr(datetime(y,m,d),formatOut),duration(h,mm,s),Scorer1_string,Scorer2_string);
    Data.Properties.VariableNames= {'Epoch','Date','Time','Scorer 1','Scorer 2'};
    writetable(Data,Output,'Sheet','Scorer_difference')
    header = {'Date generated' datetime('now');'Marker' Marker_files{i};'Scorer 1' S1_files{i};'Scorer 2' S2_files{i}};
    writecell(header,Output,'Sheet','Header');
    disagreement={'Interrater Agreement Info' [];'Total epochs' num2str(Num_label);'Total mismatch epochs' num2str(Num_diff); '% of mismatch' num2str(per_diff)};
    writecell(disagreement,Output,'Sheet','Header','Range','D1')
    Common_time=time_vec_common;
    label1=S1_label;
    label1_string=strings(length(label1),1);
    label1_string(label1==1)=string(Stage_label{1});label1_string(label1==2)=Stage_label{2};
    label1_string(label1==3)=Stage_label{3};label1_string(label1==4)=Stage_label{4};
    label1_string(label1==5)=Stage_label{5};label1_string(label1==6)=Stage_label{6};
    label2=S2_label;
    label2_string=strings(length(label2),1);
    label2_string(label2==1)=string(Stage_label{1});label2_string(label2==2)=Stage_label{2};
    label2_string(label2==3)=Stage_label{3};label2_string(label2==4)=Stage_label{4};
    label2_string(label2==5)=Stage_label{5};label2_string(label2==6)=Stage_label{6};
    Data_true= table(Common_time,label1_string,label2_string);
    Data_true.Properties.VariableNames= {'Time','Scorer 1','Scorer 2'};
    writetable(Data_true,Output,'Sheet','True Data')
    %
    file_all{i}=file;
    cum_stats1(i)=Num_label;
    cum_stats2(i)=Num_diff;
    cum_stats3(i)=per_diff;
    close all;
    fclose('all');
    system('taskkill /F /FI "WINDOWTITLE eq xy*"');
end
cum_data=table(file_all',cum_stats1',cum_stats2',cum_stats3');
cum_data.Properties.VariableNames= {'Subject name','Total epochs','Total mismatch epochs','% of mismatch'};
cum_doc=strcat('Interscorer_agreement_all.xls');
Output_cum=fullfile(directory_path,cum_doc);
writetable(cum_data,Output_cum,'Sheet','Interater agreement')
%%
function [T,time_vec,label]=Label_Marker_ID(Marker,File)
%% Marker - Light on and Light off
Marker_Time=Marker{1};
Marker_Time = strrep(Marker_Time,'.','/');
% formatout='dd-mm-yyyy HH.MM.SS';
if isempty(contains(Marker{2},'Lights Off'))|| isempty(contains(Marker{2},'Lights On'))
    disp('Error: The marker file doesnot contain lights off-on details.');
    return
end
if isempty(contains(Marker{2},'Start'))|| isempty(contains(Marker{2},'End'))
    disp('Error: The marker file doesnot contain Start and end recording details.');
    return
end
a1=contains(Marker{2},'Lights Off','IgnoreCase',true);
b1=contains(Marker{2},'Light Off','IgnoreCase',true);
if any(a1)
    LIGHTOFF=datetime((Marker_Time{contains(Marker{2},'Lights Off','IgnoreCase',true)}),'InputFormat','dd/MM/yyyy HH:mm:ss,SSS');
elseif any(b1)
    LIGHTOFF=datetime((Marker_Time{contains(Marker{2},'Light Off','IgnoreCase',true)}),'InputFormat','dd/MM/yyyy HH:mm:ss,SSS');
end
a=contains(Marker{2},'Light On','IgnoreCase',true);
b=contains(Marker{2},'Lights On','IgnoreCase',true);
if any(a)
    LIGHTON=datetime(Marker_Time{contains(Marker{2},'Light On','IgnoreCase',true)},'InputFormat','dd/MM/yyyy HH:mm:ss,SSS');
elseif any(b)
    LIGHTON=datetime(Marker_Time{contains(Marker{2},'Lights On','IgnoreCase',true)},'InputFormat','dd/MM/yyyy HH:mm:ss,SSS');
end

try
    RECSTART=datetime(Marker_Time{contains(Marker{2},'Start','IgnoreCase',true)},'InputFormat','dd/MM/yyyy HH:mm:ss,SSS','Format','dd-MMM-yyyy HH:mm:ss,SSS');
    c=find(contains(Marker{2},'End','IgnoreCase',true));
catch
    RECSTART=datetime(Marker_Time{contains(Marker{2},'Start','IgnoreCase',false)},'InputFormat','dd/MM/yyyy HH:mm:ss,SSS','Format','dd-MMM-yyyy HH:mm:ss,SSS');
    c=find(contains(Marker{2},'End','IgnoreCase',false));
end
RECEND=datetime(Marker_Time{c(end)},'InputFormat','dd/MM/yyyy HH:mm:ss,SSS');
%% hypnogram data
% % PSG
% Artefact - 6
% Wake    - 5
% REM     - 4
% N1      - 3
% N2      - 2
% N3      - 1
% Exracting the start and end date
Start_index=find(contains(string(File(:,1)),'Rate:'));
if isempty(Start_index)
    disp('The sleep profile does not match the device type chosen');
    fprintf(fileID,' %s\n','The sleep profile does not match the device type chosen');
    return
end
Stages=File(Start_index+1:end,3); % steep stages string array
St=erase(File{Start_index+1,2},';' );
Et=erase(File{end,2},';' );

a=Stages{1,1};
if ismissing(a)
    Stages=File(Start_index+1:end,2); % steep stages string array
    St=erase(File{Start_index+1,1},';' );
    Et=erase(File{end,1},';' );
end
Cp1=strsplit(St,':');
Cp1{3}=erase(Cp1{3},',000' );
St=duration(str2double(Cp1)); %mm/dd/yy
Cp2=strsplit(Et,':');
Cp2{3}=erase(Cp2{3},',000' );
Et=duration(str2double(Cp2)); %mm/dd/yy
% Extracting the date
Date=File{Start_index+1,1};
EndDate=File{end,1};
if ismissing(a)
    strt=datetime(RECSTART,'Format','dd/MM/yyyy HH:mm:ss,SSS');
    Date=string(strt);
    Cp = strsplit(Date,'/'); %mm/dd/yy
    x=Cp{3};
    x(5:end)=[];
    Cp{3}=x;
    endd=datetime(RECEND,'Format','dd/MM/yyyy HH:mm:ss,SSS');
    Cp2= strsplit(string(endd),'/'); %mm/dd/yy;
    x2=Cp2{3};
    x2(5:end)=[];
    Cp2{3}=x2;
    Date=datetime(str2double(Cp{3}),str2double(Cp{2}),str2double(Cp{1}));
    EndDate=datetime(str2double(Cp2{3}),str2double(Cp2{2}),str2double(Cp2{1}));
end
% creating the date time
Dst=Date+St;
Det=(EndDate)+Et;
% creating a time vector
time_vec=(Dst:seconds(30):Det)';
time_vec=datetime(time_vec,'Format','dd-MMM-yyyy HH:mm:ss');
% discretized sleep stages
% Creating a common notation
valueSet= ["N3","N2","N1","REM","Wake","Artefact","A"];
keySet= [1 2 3 4 5 6 6];
M = dictionary(valueSet,keySet);
label=M(string(Stages));
%
[~,ind_loff] = min(abs(time_vec-LIGHTOFF));
[~,~,sloff]=hms(LIGHTOFF);
loff_estimate=(time_vec(ind_loff)-LIGHTOFF);
if (sloff==0 && loff_estimate<0) || (sloff==30 && loff_estimate<0)
    ind_loff=ind_loff+1;
end
%
a1=datevec(LIGHTON);a=round(a1(end));
if a>15 &&a<=45
    a1(6)=0;
    LON_temp= datetime(a1);
elseif a>=0 && a<=15
    a1(6)=30;
    a1(5)=a1(5)-1;
    LON_temp= datetime(a1);
elseif a>45
    a1(6)=30;
    LON_temp= datetime(a1);
end
[~,ind_lon] = min(abs(time_vec-LON_temp));
[~,~,slon]=hms(LON_temp);
lon_estimate=(time_vec(ind_lon)-LON_temp);
if (slon==0 && lon_estimate<0) || (slon==30 && lon_estimate<0)
    ind_lon=ind_lon+1;
end
%
if ind_lon>ind_loff+960
    while label(ind_lon)==6
        ind_lon=ind_lon-1;
        if ind_lon==ind_loff+960
            break;
        end
    end
end
adj=0;
if label(ind_lon-1)~=5 && label(ind_lon)==5
    adj=0;
end

T= table(LIGHTOFF,LIGHTON,RECSTART,RECEND,ind_loff,ind_lon,Dst,Det,adj);
end
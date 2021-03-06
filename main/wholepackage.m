%% (0) INTRO

% saves pdf containing the following info:
% for each formin listed in ForminTypes.txt output:
% schematic displaying filament length and binding site location/strength
% bar graph for calculated polymerization rate for single/double/dimerized

% calls the following other scripts: 
    % gather_info.py % make_filament_schematic.m
    % find pocc.m % calculate_kpoly.m
  % the following 4 from export_fig:
    % user_string.m % using_hg2.m
    % ghostscript.m % append_pdfs.m

% imports the following look-up tables
    % ForminTypes.txt
    % single_300.txt %double_200.txt %dimer_122.txt

%% (0.1) formatting options:    
    
% if opt = 0, graphs across all formin types have same axes
% if opt = 1, each formin will have individually scaled graphs
% if opt = 2, graphs have same axes unless FH1 length is over 300 amino acids
opt1 = 1

% if opt2 = 1, graphs are titled with fh1 name and species
% if opt2 = 2, graphs are titled with fh1 name, species, length, and number binding sites
opt2 = 1

% if opt3 = 0, minimal extrapolation; excludes fh1 with length > 200
% extrapolation always occurs for dimerized > 122 (due to simulation run time)
% if opt3 = 1, all 25 fh1s included; extrapolation occurs in addition for:
    % all filiments length > 300
    % double (and dimer) with length > 200 (due to large number errors)
opt3 = 1

% if opt4 = 0, saves pdf with each formin on a different page
% if opt4 = 1, creates (but not saves) matlab figures with 3 fh1 per figure
    % if opt3 = 0, grid will have gaps in place of fh1 with length > 200
opt4 = 0

% name of outputed pdf       % must end with '.pdf'
pdf_name = 'RESULTS.pdf';

% location of look-up tables
path = '../../PolymerData/' ;


%% (1) read output files and extract all values of p_occ

m1 = dlmread(append(path,'single1_300.txt'));
m2 = dlmread(append(path,'double_200.txt'));
m3 = dlmread(append(path,'dimer_122.txt'));

find_pocc

%% (2) Further Initialization

% retrives all names and uniprot queries of formin types into seperate strings
Name_Query = char(importdata('ForminTypes.txt'));
Name_Query = strsplit(Name_Query);

% adds current matlab path to python paths if necessary
if count(py.sys.path,'') == 0
    insert(py.sys.path,int32(0),'');
end

for LOOP = 1:length(Name_Query)/2
    
fh1_name = convertCharsToStrings(Name_Query(2*LOOP -1));
query = convertCharsToStrings(Name_Query(2*LOOP));

%     fh1_name = 'fhod3-human'
%     query = 'Q2V2M9 ' % use thise lines (and comment out for loop) to test for 1 specific formin

%% (3) Calls Python and UNIPROT

%calls py script to get polymer stats from UNIPROT
x = py.gather_info.gathering(query);

%changes variable format to matlab doubles
fh1_length = cell2mat(x(1));
x2 = {cell(x(2))}; %pp_index_vec
x2 = x2{1}{1};
pp_index_vec = [];
for i = 1:length(x2)
    pp_index_vec = [pp_index_vec x2{i}]; %locations of binding sites along a single filament
end
x3 = {cell(x(3))}; %pp_length_vec
x3 = x3{1}{1};
pp_length_vec = [];
for i = 1:length(x3)
    pp_length_vec = [pp_length_vec x3{i}]; %number of polyprorlines at each binding site
end

%sets more variables and constants
iSite_tot = length(pp_index_vec); %number of total binding sites on one filament

% skips fh1 with length over 200 based on chosen opt3
if opt3 == 0
 if fh1_length > 200
     continue
 end
end

%% (4) interpolating and graphing
% interpolates values of p_occ using inputed files from (1)
% makes filament schematic
% calculates/graphs polymerization rate

fh1_length_vec = fh1_length*ones(length(pp_index_vec),1);
pp_percentage_vec = transpose(1/fh1_length*pp_index_vec);


p_occ1 = [];
p_occ2a = [];
p_occ2b = [];
p_occ3a = [];
p_occ3b = [];

% extracts specific probabilities for current fh1 from arrays set in find_pocc 
% see (intro) regarding which probabilities are extrapolated
% if not extrapolated, exact simulated probabilities used
if fh1_length <= 300
    [row,~] = find(X1(:,1) == fh1_length & X1(:,2) == pp_index_vec);
    p_occ1 = X1(row,3);
    
    if fh1_length <= 200
        [row,~] = find(X2a(:,1) == fh1_length & X2a(:,2) == pp_index_vec);
        p_occ2a = X2a(row,3);
        [row,~] = find(X2b(:,1) == fh1_length & X2b(:,2) == pp_index_vec);
        p_occ2b = X2b(row,3);
    else
        p_occ2a = F2a(fh1_length_vec,pp_index_vec');
        p_occ2b = F2b(fh1_length_vec,pp_index_vec');
    end
    
    if fh1_length <= 121
         [row,~] = find(X3a(:,1) == fh1_length & X3a(:,2) == pp_index_vec);
         p_occ3a = X3a(row,3);
         [row,~] = find(X3b(:,1) == fh1_length & X3b(:,2) == pp_index_vec);
         p_occ3b = X3b(row,3);
    else
        p_occ3a = F3a(fh1_length_vec,pp_index_vec');
        p_occ3b = F3b(fh1_length_vec,pp_index_vec');
    end
else 
    p_occ1 = F1(fh1_length_vec,pp_index_vec');
    p_occ2a = F2a(fh1_length_vec,pp_index_vec');
    p_occ2b = F2b(fh1_length_vec,pp_index_vec'); 
    p_occ3a = F3a(fh1_length_vec,pp_index_vec');
    p_occ3b = F3b(fh1_length_vec,pp_index_vec');
end

% sets title containing name, length, and number of binding sites
% used based on opt2
lenstr = num2str(fh1_length);
iSitestr = num2str(iSite_tot);
fh1_info = strcat(fh1_name,' \\ Length = ',lenstr,' \\ ',iSitestr,' binding sites');

% creates all graphs
make_filament_schematic

calculate_kpoly


%% (5) create pdfs

%appends all pdfs into one document called pdf_name

if opt4 == 0
    if LOOP == 1
        saveas(gcf, pdf_name) 
    end

    if LOOP > 1
        saveas(gcf, append('temp.pdf'))
        append_pdfs(pdf_name, append('temp.pdf'))
    end
else
    if LOOP == 3
        saveas(gcf, pdf_name)
    end
    if LOOP > 3 && rem(LOOP,3) == 0
        saveas(gcf, append('temp.pdf'))
        append_pdfs(pdf_name, append('temp.pdf'))
    end
end
    


end
 
if opt4 == 1
    if rem(LOOP,3) == 0
        
    else
        saveas(gcf, append('temp.pdf'))
        append_pdfs(pdf_name, append('temp.pdf'))
    end
end
        
% deletes temporary pdf and closes all matlab figures

close all
delete 'temp.pdf'




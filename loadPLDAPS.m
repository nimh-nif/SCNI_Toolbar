function loadPLDAPS()
%loadPLDAPS   load the pldaps folders into the matlab path

    %add the path to you PLDAPS code and other Dirs you want to have added
    %(your stimuli
    dirs{1}='/projects/SCNI/PLDAPS';
%     dirs{2}='~/Documents/stimuli';

    for j=1:length(dirs)
        a=genpath(dirs{j});
        b=textscan(a,'%s','delimiter',':');
        b=b{1};
        b(~cellfun(@isempty,strfind(b,'.git')))=[];
        addpath(b{:})
        fprintf('%s added to the path\n', dirs{j});
    end
end
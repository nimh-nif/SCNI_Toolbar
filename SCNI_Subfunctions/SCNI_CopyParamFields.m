function Params = SCNI_CopyParamFields(ParamsFileOld, ParamsFileNew)

%====================== SCNI_CopyParamFields.m ============================
% After SCNI_Toolbar functions have been updated, parameters (.mat) files
% may not contain all the necessary fields that new functions require. This
% function compares the fields of an existing parameters file with those of
% and updated parameters file (e.g. from a different computer) and appends
% any new fields that are missing using default values. These values may
% need to be updated if they are specific to certain setups, but this
% should be acheived through the appropriate SCNI_Toolbar GUIs.

ParamsOld   = load(ParamsFileOld);
OldFields   = fieldnames(ParamsOld);

ParamsNew   = load(ParamsFileNew);
NewFields   = fieldnames(ParamsNew);

Count       = [0,0];
for f = 1:numel(NewFields)
    if ~ismember(OldFields, NewFields{f})
        fprintf('Appending new field ''%s'' to Params file %s...\n', NewFields{f}, ParamsFileOld);
        eval(sprintf('ParamsOld.%s = ParamsNew.%s;', NewFields{f}, NewFields{f}));
        Count(1) = Count(1)+1;
    else
        if ~ischar(eval(sprintf('ParamsOld.%s', NewFields{f})))
            OldSubfields = fieldnames(eval(sprintf('ParamsOld.%s', NewFields{f})));
            NewSubfields = fieldnames(eval(sprintf('ParamsNew.%s', NewFields{f})));
            for sf = 1:numel(NewSubfields)
                if ~ismember(OldSubfields, NewSubfields{sf})
                    eval(sprintf('ParamsOld.%s.%s = ParamsNew.%s.%s;', NewFields{f}, NewSubfields{sf}, NewFields{f}, NewSubfields{sf}));
                    Count(2) = Count(2)+1;
                end
            end
        end
    end
end
fprintf('\nSummary: %d fields and %d subfields were added to %s.\n', Count(1), Count(2), ParamsFileOld);
Params      = ParamsOld;
ParamsFile  = ParamsFileOld;
FieldNames  = fieldnames(Params);
for f = 1:numel(FieldNames)
    eval(sprintf('%s   = Params.%s;', FieldNames{f}, FieldNames{f})); 
  	eval(sprintf('save(ParamsFile, ''%s'', ''-append'');', FieldNames{f}));
end
classdef Notebook < handle
    properties
        name
        root
        lib
        uuid
        metaFile
        
        notes % MRU first when created
    end
    
    properties(Dependent)
        noteMRU
        updated_at
    end
    
    methods
        function nb = Notebook(nbPath, lib)
            nbPath = Quiver.Utils.GetFullPath(nbPath);
            assert(nargin > 1 && ~isempty(nbPath), 'Must provide path to notebook directory');
            nb.root = nbPath;
            nb.metaFile = fullfile(nbPath, 'meta.json');
            nb.lib = lib;
            nb.refresh();
        end
        
        function refresh(nb)
            % get name from meta.json
            if ~exist(nb.metaFile, 'file')
                error('Could not locate notebook meta.json file %s', nb.metaFile);
            end
            info = loadjson(nb.metaFile);
            nb.uuid = info.uuid;
            nb.name = info.name;
            
            % loop through notes
            info = dir(fullfile(nb.root, '*.qvnote'));
            
            names = {info.name}'; % file names in UUID format
            
            notes = cell(numel(names), 1); %#ok<*PROP>
            for iN = 1:numel(names)
                nRoot = fullfile(nb.root, names{iN});
                notes{iN} = Quiver.Note(nRoot, nb);
            end
            
            nb.notes = cat(1, notes{:});
            
            % sort by most recently updated
            if numel(nb.notes) > 1
                [~, sortIdx] = sort([nb.notes.updated_at], 'descend');
                nb.notes = nb.notes(sortIdx);
            end
        end

        function time = get.updated_at(nb)
            if isempty(nb.notes)
                time = NaN;
            else
                time = max([nb.notes.updated_at]);
            end
        end
        
        function note = get.noteMRU(nb)
            if isempty(nb.notes)
                note = [];
            else
                [~, ind] = max([nb.notes.updated_at]);
                note = nb.notes(ind);
            end
        end
    end
end

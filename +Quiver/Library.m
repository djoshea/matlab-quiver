classdef Library < handle
    properties
        name
        root
        notebooks
    end
    
    properties(Dependent)
        notebookMRU % most recently updated
        noteMRU % most recently updated
    end
        
    methods
        function lib = Library(libPath)
            if nargin < 1
                libPath = getenv('QUIVER_LIBRARY');
            end
            libPath = Quiver.Utils.GetFullPath(libPath);
            assert(exist(libPath, 'dir') > 0, 'Library path not found');
            [~, lib.name, ext] = fileparts(libPath);
            assert(strcmp(ext, '.qvlibrary'), 'Library path must end in .qvlibrary');
            lib.root = libPath;
            
            lib.refresh();
        end
        
        function refresh(lib)
            info = dir(fullfile(lib.root, '*.qvnotebook'));
            
            names = {info.name}'; % file names in UUID format
            
            nbs = cell(numel(names), 1);
            for iN = 1:numel(names)
                nbRoot = fullfile(lib.root, names{iN});
                nbs{iN} = Quiver.Notebook(nbRoot, lib);
            end
            
            lib.notebooks = cat(1, nbs{:});
        end
        
        function nb = get.notebookMRU(lib)
            [~, ind] = max(arrayfun(@(nb) nb.updated_at, lib.notebooks));
            nb = lib.notebooks(ind);
        end
        
        function note = get.noteMRU(lib)
            note = lib.notebookMRU.noteMRU;
        end
    end
    
    
end
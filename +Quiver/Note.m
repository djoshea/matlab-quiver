classdef Note < handle
    properties
        title
        root
        notebook
        uuid
        metaFile
        contentFile
        
        created_at
        updated_at
        tags
    end
    
    methods
        function note = Note(notePath, nb)
            notePath = Quiver.Utils.GetFullPath(notePath);
            assert(nargin > 1 && ~isempty(notePath), 'Must provide path to note directory');
            note.root = notePath;
            note.metaFile = fullfile(notePath, 'meta.json');
            note.contentFile = fullfile(notePath, 'content.json');
            note.notebook = nb;
            note.refresh();
        end
        
        function refresh(note)
            % get name from meta.json
            if ~exist(note.metaFile, 'file')
                error('Could not locate note meta.json file %s', note.metaFile);
            end
            meta = loadjson(note.metaFile);
            note.uuid = meta.uuid;
            note.title = meta.title;
            
            note.created_at = unixtime_to_datenum(meta.created_at);
            note.updated_at = unixtime_to_datenum(meta.updated_at);
            note.tags = meta.tags;
            
            function dn = unixtime_to_datenum(unixtime)
                dn = unixtime/86400 + 719529; % == datenum(1970,1,1)
            end
        end
        
        function json = readContents(note)
            json = loadjson(note.contentFile);
        end
        
        % Authoring tools
        function writeContents(note, json)
            savejson('', json, note.contentFile);
        end
        
        function appendCell(note, type, data)
            json = note.readContents;
            json.cells{end+1} = struct('type', type, 'data', data);
            
            note.writeContents(json);
        end
        
        function appendTextCell(note, data)
            note.appendCell('text', data);
        end
        
        function appendMarkdownCell(note, data)
            note.appendCell('markdown', data);
        end
        
        function appendFigure(note, varargin)
            % append a specific template for a matlab figure using 
            % matlab-save-figure
            % Usage: appendFigure([figh=gcf], varargin)
            
            p = inputParser();
            p.addOptional('figh', gcf, @ishandle);
            p.addParameter('embedExt', 'svg', @ischar);
            p.addParameter('ext', {'svg', 'pdf', 'png', 'fig'}, @iscellstr);
            p.addParameter('title', '', @ischar);
            p.addParameter('caption', '', @ischar);
            p.parse(varargin{:});
            
            % save the figure in multiple formats
            embedExt = p.Results.embedExt;
            stem = tempname;
            exts = p.Results.ext;
            
            saveFigure(stem, p.Results.figh, 'ext', exts);
            
            % generate the relative urls to the images
            urls = cell(numel(exts), 1);
            for iE = 1:numel(exts)
                f = note.addFile([stem '.' exts{iE}]);
                if strcmp(exts{iE}, embedExt)
                    urls{iE} = ['quiver-image-url/', f];
                else
                    urls{iE} = ['quiver-file-url/', f];
                end
            end
            
            % generate the html around the figure
            embedImage = sprintf('<div class="svg-container"><img src="%s" /></div>', urls{1});
            dataParts = cell(1, numel(exts)-1);
            for iE = 2:numel(exts)
                if iE == numel(exts)
                    atEnd = '';
                else
                    atEnd = ' ';
                end
                dataParts{iE-1} = sprintf('<a href="%s">%s</a>%s', urls{iE}, exts{iE}, atEnd);
            end
            
            if isempty(p.Results.title)
                titleHtml = '';
            else
                titleHtml = sprintf('<h3 class="title">%s</h3>', p.Results.title);
            end
            
            if isempty(p.Results.caption)
                captionHtml = '';
            else
                captionHtml = ['<div class="caption">', splitParagraphs(p.Results.caption), '</div>'];
            end
            
            data = ['<div class="matlab-figure">', titleHtml, embedImage, ...
                '<div class="link-container">', cat(2, dataParts{:}), ...
                '</div>', captionHtml, '</div>'];
            
            note.appendTextCell(data);
            
            function html = splitParagraphs(str)
                split = strsplit(str, '\n');
                html = sprintf('<p>%s</p>', split{:});
            end
        end
        
        function [fileName, newPath] = addFile(note, filePath)
            % copies a file as a resource to the resources folder of this
            % note 
            assert(exist(filePath, 'file') > 0, 'File not found');
            resPath = fullfile(note.root, 'resources');
            mkdir(resPath);
            [~, ~, ext] = fileparts(filePath);
            uuid = upper(char(java.util.UUID.randomUUID));
            fileName = [uuid, ext]; %#ok<*PROPLC>
            newPath = fullfile(resPath, fileName);
            copyfile(filePath, newPath);
        end
        
    end
end

classdef DexConfig < matlab.mixin.indexing.RedefinesDot & matlab.mixin.Scalar
    %CONFIGURATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        data = []
    end

    properties (Dependent)
        FieldNames
        NumElements
        DataTypes
        Sizes
        Families
    end

    %% Get Methods
    methods
        function out = get.FieldNames(obj)
            out = [obj.data.var]';
        end
        function out = get.NumElements(obj)
            out = length(obj.data);
        end
        function out = get.DataTypes(obj)
            out = strings(obj.NumElements,1);
            for n = 1:obj.NumElements
                out(n) = string(class(obj.data(n).value));
            end
        end
        function out = get.Sizes(obj)
            out = NaN(obj.NumElements, 2);
            for n = 1:obj.NumElements
                out(n,:) = size(obj.data(n).value);
            end
        end
        function out = get.Families(obj)
            out = unique([obj.data.family], 'stable')';
            % No family belongs to the "" family
        end
    end
    
    %% Constructor
    methods (Access=public)
        function obj = DexConfig()
            return
        end
    end

    %% Public Methods
    methods (Access=public)
        
    end

    %% Dot Index Overloads
    methods (Access=protected)
        function varargout = dotReference(obj,indexOp)
            idx = v2i(obj, indexOp(1).Name);
            ThisData = obj.data(idx).value;
            if length(indexOp) == 1
                varargout{1} = ThisData;
                return
            end
            % otherwise we need to handle the subsequent indexing :(
            for idx = 2:length(indexOp)
                ThisOp = indexOp(idx);
                switch ThisOp.Type
                    case "Dot"
                        ThisData = ThisData.(ThisOp.Name);
                    case "Paren"
                        ThisData = ThisData(ThisOp.Indices{1});
                    case "Brace"
                        ThisData = ThisData{ThisOp.Indices{1}};
                end
            end
            varargout{1} = ThisData;
        end

        function obj = dotAssign(obj,indexOp,varargin)
            % First check if this index is valid
            if ~ismember(indexOp.Name, obj.FieldNames)
                error("%s is not a property created with AddProp.", indexOp.Name)
            end
            % Valid field name, assing value
            idx = v2i(obj, indexOp.Name);
            NewValue = varargin{1};
            if ~isa(NewValue, class(obj.data(idx).value))
                % Class missmatch, likely an error
                error("Cannot change class of data. Class for old data was %s while class of new data is %s.", class(NewValue), class(obj.data(idx).value))
            end
            obj.data(idx).value = NewValue;
        end
        
        function n = dotListLength(obj,indexOp,indexContext)
            n = 1; % Always return one value via this method
            %n = listLength([obj.data.var], indexOp, indexContext);
        end
    end

    %% 

    methods
        function out = GetProp(obj, varName)
            idx = obj.v2i(varName);
            out = obj.data(idx).value;
        end
        function obj = ChangeProp(obj, varName, value)
            arguments
                obj
                varName (1,1) string
                value
            end
            if ~ismember(varName, [obj.data.var])
                error("varName must be one of the existing properties in the config.")
            end
            idx = obj.v2i(varName);
            obj.data(idx).value = value;
        end
        function obj = AddProp(obj, varName, value, opts)
            arguments
                obj
                varName (1,1) string
                value 

                opts.label (1,1) string = ""
                opts.family (1,1) string = "Misc"
                opts.type (1,1) string {mustBeMember(opts.type, ["num", "text", "list","table"])} = "num"
                opts.range (1,2)  = [-inf inf]
                opts.list (1,:) string = ""
            end
            NewIdx = length(obj.data) + 1;
            obj.data(NewIdx).var = varName;
            obj.data(NewIdx).label = opts.label;
            obj.data(NewIdx).value = value;
            obj.data(NewIdx).family = opts.family;
            obj.data(NewIdx).type = opts.type;
            obj.data(NewIdx).range = opts.range;
            obj.data(NewIdx).list = opts.list;
        end
        function obj = rmProp(obj, propVarName)
            idx = obj.v2i(propVarName);
            if isempty(idx)
                error("Could not find property with variable name: %s", propVarname)
            end
            obj.data(NewIdx) = [];
        end

        function handles = FillGuiGrid(obj, g, opts)
            arguments
                obj
                g
                opts.HeaderFontSize = 18;
                opts.BodyFontSize = 14;
            end
            % given a graphics object grid 'g', fill the grid with
            % properties and their values
            handles.MainGrid = uigridlayout(g, [length(obj.Families),1], "Scrollable","on",...
                "RowHeight",repmat({'fit'}, length(obj.Families), 1), ...
                'RowSpacing',20);
            for f = 1:length(obj.Families)
                ThisFamily = obj.Families(f);
                handles.FamPanel(f) = uipanel(handles.MainGrid, ...
                    "Title", ThisFamily, ...
                    "TitlePosition","lefttop",...
                    'FontSize', opts.HeaderFontSize,...
                    'FontWeight','bold');
                FamilyMask = [obj.data.family] == ThisFamily;
                FamIndex = find(FamilyMask);
                handles.ItemGrid(f) = uigridlayout(handles.FamPanel(f), [length(FamIndex),2],...
                    "RowHeight",repmat({'fit'}, length(FamIndex), 1));
                for item = FamIndex
                    uilabel(handles.ItemGrid(f), "Text", obj.data(item).label);
                    switch obj.data(item).type
                        case "num"
                            handles.var.(obj.data(item).var) = uieditfield(handles.ItemGrid(f), "numeric", ...
                                'value', obj.data(item).value,...
                                'Limits',obj.data(item).range);
                        case "text"
                            handles.var.(obj.data(item).var) = uieditfield(handles.ItemGrid(f), "text", ...
                                'value', obj.data(item).value);
                        case "list"
                            handles.var.(obj.data(item).var) = uidropdown(handles.ItemGrid(f), "Items", obj.data(item).list, 'Value', obj.data(item).value);
                        case "table"
                            handles.var.(obj.data(item).var) = uitable(handles.ItemGrid(f), "Data", obj.data(item).value);
                    end
                end
                set(allchild(handles.ItemGrid(f)), 'fontsize', opts.BodyFontSize)
            end
        end
        function [obj, delta] = ExtractPropsFromHandles(obj, handles)
            % Assume handles was sourced using FillGuiGrid
            DeltaIdx = 0;
            delta = [];
            for n = 1:obj.NumElements
                ThisVar = obj.data(n).var;
                switch obj.data(n).type
                    case "text"
                        value = string(handles.var.(ThisVar).Value);
                    case "num"
                        value = handles.var.(ThisVar).Value;
                    case "list"
                        value = string(handles.var.(ThisVar).Value);
                    case "table"
                        value = handles.var.(ThisVar).Data;
                end
                % % Guard for table values
                % if istable(value)
                %     % Check each column of table data
                %     NoChange = true;
                %     for k = 1:width(value)
                %         obj.data.value{:,k} == value{:,k}
                %     end
                %     continue
                % end
                if obj.data(n).value ~= value
                    % Change!
                    DeltaIdx = DeltaIdx + 1;
                    delta(DeltaIdx).var = ThisVar;
                    delta(DeltaIdx).value = value;
                    obj = obj.ChangeProp(ThisVar, value);
                end
            end
        end
    end

    methods (Access=private)
        function out = v2i(obj, varName)
            out = find([obj.data.var] == varName);
        end
    end
    
end


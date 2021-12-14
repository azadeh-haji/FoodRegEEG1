function index = searchcell(cellArray,value, varargin)

%  function index = searchcell(cellArray,value)
%  searches a cell array and returns the cell index containing the
%  specified value
%
%  Author: Cendri Hutcherson
%  Date: 2.17.09

if isempty(varargin)
    type = 'exact';
else
    type = varargin{1};
end

isTrue = zeros(1,length(cellArray));

switch type
    case 'exact'
        if isnan(value)
            for i = 1:length(cellArray)
                isTrue(i) = isnan(cellArray{i});
            end
        else
            for i = 1:length(cellArray)
                isTrue(i) = isequal(cellArray{i},value);
            end
        end
    case 'contains'
        for i = 1:length(cellArray)
            isTrue(i) = ~isempty(regexp(cellArray{i},value,'once'));
        end
end

index = find(isTrue==1);
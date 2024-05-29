% Converts a column pasted from Excel into an array to use in our table.
function data = getTableFromClipboard

data = clipboard('paste');
if(isempty(data))
    msgbox('Nothing on the clipboard. Paste Failed.','No Data to Paste.');
    data = [];
else
    data = str2num(data);
    if any(any(isnan(data)))
        msgbox('Unable to paste column. Possibly non-numerical data.', 'Bad Column Data');
        data = [];
    end
end
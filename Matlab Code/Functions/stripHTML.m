% stripHTML removes the HTML tags from the input string.
% Input must be valid HTML
function markDown = stripHTML(html)
   pat = '<[^>]*>';
   markDown = regexprep(html, pat, '');
end
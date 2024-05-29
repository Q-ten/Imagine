function [regionCells, region, rowOffset] = getRangeRegionFromAnchor(ws, rangeAnchorName)

    anchor = ws.Range(rangeAnchorName);
    anchorRow = get(anchor, 'Row');
    
    region = get(anchor, 'CurrentRegion');
    regionRow = get(region, 'Row');
    
    regionCells = region.Value;
    
    rowOffset = anchorRow - regionRow + 1;
    regionCells = regionCells(rowOffset:end, :);

end
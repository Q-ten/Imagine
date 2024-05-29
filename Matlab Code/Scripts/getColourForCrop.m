function colour = getColourForCrop(cropName)

    switch cropName
        case 'Wheat'
            colour = [.12 .74 .12];
        case 'Barley'            
            colour = [1 0.8 0];
        case 'Canola'            
            colour = [1 1 0];
        case 'Lupins'            
            colour = [.85 0.7 1];
       case 'Peas'            
            colour = [.169 .506 .337];
       case 'Pasture'            
            colour = [0 1 0];
        case 'Fallow'            
            colour = [.6 0.2 0];
         otherwise            
            colour = rand(1, 3);
    end

end
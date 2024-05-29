function prob = cumulativeProb(independentProbs)

    totalProb = 0;

    for i = 1:length(independentProbs)
        probNotHappenedYet = 1 - totalProb;
        totalProb = totalProb + probNotHappenedYet * independentProbs(i);
    end
    
    prob = totalProb;
end
% Follows a model based on Gompertz, but with two state, each
% dependant on the other. The growth rates alpha and beta are
% calculated first (and are dependant on both states), but then
% each state follows a 'natural' gompertz curve, as can be seen in
% the lower equations.
function newState = ABGompertzPropagateState(state, propParams, year, month, rain, plantMonth)

    A = state.AGBM;
    B = state.BGBM;
    dt = 1/12; % Assumes 1 whole month

    A_rain_multiplier = propParams.alpha_nom / (propParams.nom_rain - propParams.A_sustaining_rainfall) ...
        / (propParams.nom_rain - 2*propParams.A_optimal_rainfall + propParams.A_sustaining_rainfall);

    B_rain_multiplier = propParams.beta_nom / (propParams.nom_rain - propParams.B_sustaining_rainfall) ...
        / (propParams.nom_rain - 2*propParams.B_optimal_rainfall + propParams.B_sustaining_rainfall);    

    rainBasedAlpha = (rain - propParams.A_sustaining_rainfall) * (rain - 2*propParams.A_optimal_rainfall + propParams.A_sustaining_rainfall) * A_rain_multiplier;
    rainBasedBeta = (rain - propParams.B_sustaining_rainfall) * (rain - 2*propParams.B_optimal_rainfall + propParams.B_sustaining_rainfall) * B_rain_multiplier;

    alpha = (propParams.alpha_coppice - rainBasedAlpha) * exp(-propParams.alpha_slope * A/B) + rainBasedAlpha;
    beta = (propParams.beta_coppice - rainBasedBeta) * exp(-propParams.beta_slope * A/B) + rainBasedBeta;

    % apply initial boost
    t_years = year - 1 + month / 12 - plantMonth/12;
    boostMultiplier = (propParams.initialBoost) * 0.5 ^ (t_years / propParams.boostHalfLife);
    alpha = alpha + boostMultiplier;
    beta = beta + boostMultiplier;


    newState.AGBM = propParams.KA * exp(log(A/propParams.KA) * exp(-alpha * dt));
    newState.BGBM = propParams.KB * exp(log(B/propParams.KB) * exp(-beta * dt));
    
    if isnan(newState.AGBM)
        newState.AGBM = 0;
        newState.BGBM = 0;
    end
    
end



var convertTemp = func 
{
    var degF = getprop("engines/engine[0]/egt_degf");  
    if (degF == nil) degF = 0.0;
    var degC = (degF - 32) * 5/9;
    
    setprop("engines/engine[0]/egt-degc", degC); 
    var degF = getprop("engines/engine[1]/egt_degf");  
    if (degF == nil) degF = 0.0;
    
    var degC = (degF - 32) * 5/9; 
    setprop("engines/engine[1]/egt-degc", degC);

    settimer(convertTemp, 0.1);

}

setlistener("sim/signals/fdm-initialized", convertTemp);

#############################################################################
# 777 Autopilot Flight Director System
# Syd Adams
#speed modes  = THR,THR REF, IDLE,HOLD,SPD;
# roll modes = TO/GA,HDG SEL,HDG HOLD, LNAV,LOC,ROLLOUT,TRK SEL, TRK HOLD,ATT;
# pitch modes TO/GA,ALT,V/S,VNAV PTH,VNAV SPD,VNAV ALT,G/S,FLARE,FLCH SPD,FPA;
# FPA range: -9.9 ~ 9.9 degrees
# VS range : -8000 ~ 6000
# ALT range  : 0 ~ 50,000
#
#############################################################################

#Usage : var afds = AFDS.new();

var AFDS = {
    new : func{
        var m = {parents:[AFDS]};

        m.spd_list=["","THR","THR REF","HOLD","IDLE","SPD"];

        m.roll_list=["TO/GA","HDG SEL","HDG HOLD","LNAV","LOC","ROLLOUT",
        "TRK SEL","TRK HOLD","ATT"];

        m.pitch_list=["TO/GA","ALT","V/S","VNAV PTH","VNAV SPD",
        "VNAV ALT","G/S","FLARE","FLCH SPD","FPA"];

        m.step=0;

        m.AFDS_node = props.globals.getNode("instrumentation/afds",1);
        m.AFDS_inputs = m.AFDS_node.getNode("inputs",1);
        m.AFDS_apmodes = m.AFDS_node.getNode("ap-modes",1);
        m.AFDS_settings = m.AFDS_node.getNode("settings",1);
        m.AP_settings = props.globals.getNode("autopilot/settings",1);

        m.AP = m.AFDS_inputs.initNode("AP",0,"BOOL");
        m.AP_disengaged = m.AFDS_inputs.initNode("AP-disengage",0,"BOOL");
        m.AP_passive = props.globals.initNode("autopilot/locks/passive-mode",1,"BOOL");

        m.FD = m.AFDS_inputs.initNode("FD",0,"BOOL");
        m.at1 = m.AFDS_inputs.initNode("at-armed[0]",0,"BOOL");
        m.at2 = m.AFDS_inputs.initNode("at-armed[1]",0,"BOOL");
        m.alt_knob = m.AFDS_inputs.initNode("alt-knob",0,"BOOL");
        m.autothrottle_mode = m.AFDS_inputs.initNode("autothrottle-index",0,"INT");
        m.lateral_mode = m.AFDS_inputs.initNode("lateral-index",0,"INT");
        m.vertical_mode = m.AFDS_inputs.initNode("vertical-index",0,"INT");
        m.gs_armed = m.AFDS_inputs.initNode("gs-armed",0,"BOOL");
        m.loc_armed = m.AFDS_inputs.initNode("loc-armed",0,"BOOL");
        m.vor_armed = m.AFDS_inputs.initNode("vor-armed",0,"BOOL");
        m.ias_mach_selected = m.AFDS_inputs.initNode("ias-mach-selected",0,"BOOL");
        m.hdg_trk_selected = m.AFDS_inputs.initNode("hdg-trk-selected",0,"BOOL");
        m.vs_fpa_selected = m.AFDS_inputs.initNode("vs-fpa-selected",0,"BOOL");
        m.bank_switch = m.AFDS_inputs.initNode("bank-limit-switch",0,"INT");

        m.ias_setting = m.AP_settings.initNode("target-speed-kt",250);# 100 - 399 #
        m.mach_setting = m.AP_settings.initNode("target-speed-mach",0.40);# 0.40 - 0.95 #
        m.vs_setting = m.AP_settings.initNode("vertical-speed-fpm",0); # -8000 to +6000 #
        m.hdg_setting = m.AP_settings.initNode("heading-bug-deg",360,"INT");
        m.fpa_setting = m.AP_settings.initNode("flight-path-angle",0); # -9.9 to 9.9 #
        m.alt_setting = m.AP_settings.initNode("target-altitude-ft",10000,"DOUBLE");
        m.auto_brake_setting = m.AP_settings.initNode("autobrake",0.000,"DOUBLE");

        m.trk_setting = m.AFDS_settings.initNode("trk",0,"INT");
        m.vs_display = m.AFDS_settings.initNode("vs-display",0);
        m.fpa_display = m.AFDS_settings.initNode("fpa-display",0);
        m.bank_min = m.AFDS_settings.initNode("bank-min",-30);
        m.bank_max = m.AFDS_settings.initNode("bank-max",30);
        m.vnav_alt = m.AFDS_settings.initNode("vnav-alt",35000);
        m.lnav_heading = m.AFDS_settings.initNode("lnav-crs",0);

        m.AP_roll_mode = m.AFDS_apmodes.initNode("roll-mode","TO/GA");
        m.AP_roll_arm = m.AFDS_apmodes.initNode("roll-mode-arm"," ");
        m.AP_pitch_mode = m.AFDS_apmodes.initNode("pitch-mode","TO/GA");
        m.AP_pitch_arm = m.AFDS_apmodes.initNode("pitch-mode-arm"," ");
        m.AP_speed_mode = m.AFDS_apmodes.initNode("speed-mode","");
        m.AP_annun = m.AFDS_apmodes.initNode("mode-annunciator"," ");
        m.AP_throttle1 = m.AFDS_apmodes.initNode("throttle[0]"," ");
        m.AP_throttle2 = m.AFDS_apmodes.initNode("throttle[1]"," ");

        m.APl = setlistener(m.AP, func m.setAP(),0,0);
        m.Lbank = setlistener(m.bank_switch, func m.setbank(),0,0);
        return m;
    },

####    Inputs    ####
###################
    input : func(mode,btn){
        if(mode==0){
            if(me.lateral_mode.getValue() ==btn) btn=0;
            me.lateral_mode.setValue(btn);
        }elsif(mode==1){
            if(me.vertical_mode.getValue() ==btn) btn=0;
            me.vertical_mode.setValue(btn);
        }elsif(mode==2){
            if(me.autothrottle_mode.getValue() ==btn) btn=0;
            me.autothrottle_mode.setValue(btn);
        }
    },
###################
    setAP : func{
        var output=1-me.AP.getValue();
        var disabled = me.AP_disengaged.getValue();
        if(disabled)output = 1;
        me.AP_passive.setValue(output);
    },
###################
    setbank : func{
        var banklimit=me.bank_switch.getValue();
        var lmt=30;
        if(banklimit>0){lmt=banklimit * 5};
        me.bank_max.setValue(lmt);
        lmt = -1 * lmt;
        me.bank_min.setValue(lmt);
    },

#################

    ap_update : func{
        var VS =getprop("velocities/vertical-speed-fps");
        var TAS =getprop("velocities/uBody-fps");
        if(TAS == 0.000)TAS=0.001;
        var FPangle = math.asin(VS/TAS) * 90;
        setprop("autopilot/internal/fpa",FPangle);
        var msg=" ";
        if(me.FD.getValue())msg="FLT DIR";
        if(me.AP.getValue())msg="AP ENG";
        me.AP_annun.setValue(msg);
        var tmp = abs(me.vs_setting.getValue());
        me.vs_display.setValue(tmp);
        tmp = abs(me.fpa_setting.getValue());
        me.fpa_display.setValue(tmp);
        msg="";
        if(getprop("position/altitude-agl-ft")<200){
            me.AP.setValue(0);
        }

        if(me.step==0){ ### glidesloped armed ?###
            msg="";
            if(me.gs_armed.getValue()){
                msg="G/S";
                var gsdefl = getprop("instrumentation/nav/gs-needle-deflection");
                var gsrange = getprop("instrumentation/nav/gs-in-range");
                if(gsdefl< 0.5 and gsdefl>-0.5){
                    if(gsrange){
                        me.vertical_mode.setValue(6);
                        me.gs_armed.setValue(0);
                    }
                }
            }
            me.AP_pitch_arm.setValue(msg);

        }elsif(me.step==1){ ### localizer armed ? ###
            msg="";
            if(me.loc_armed.getValue()){
                msg="LOC";
                var hddefl = getprop("instrumentation/nav/heading-needle-deflection");
                if(hddefl< 8 and hddefl>-8){
                    me.lateral_mode.setValue(4);
                    me.loc_armed.setValue(0);
                }
            }
            me.AP_roll_arm.setValue(msg);

        }elsif(me.step==2){ ### check lateral modes  ###
            var idx=me.lateral_mode.getValue();
            me.AP_roll_mode.setValue(me.roll_list[idx]);

        }elsif(me.step==3){ ### check vertical modes  ###
            var idx=me.vertical_mode.getValue();
            var test_fpa=me.vs_fpa_selected.getValue();
            if(idx==2 and test_fpa)idx=9;
            if(idx==9 and !test_fpa)idx=2;
            me.AP_pitch_mode.setValue(me.pitch_list[idx]);

        }elsif(me.step==4){             ### check speed modes  ###
            var idx=me.autothrottle_mode.getValue();
            var test_speed=me.ias_mach_selected.getValue();
            var th1="";
            var th2="";
            if(idx==1){
                 if(test_speed){
                    if(me.at1.getValue())th1="mach";
                    if(me.at2.getValue())th2="mach";
                 }else{
                    if(me.at1.getValue())th1="ias";
                    if(me.at2.getValue())th2="ias";
                 }
            }
                me.AP_throttle1.setValue(th1);
                me.AP_throttle2.setValue(th2);
                me.AP_speed_mode.setValue(me.spd_list[idx]);
        }

        if(getprop("autopilot/route-manager/route/num")>0){
            crs=getprop("autopilot/internal/true-heading-error-deg");
        }else{
            crs=getprop("autopilot/internal/nav1-course-error");
        }
        me.lnav_heading.setValue(crs);

        me.step+=1;
        if(me.step>4)me.step =0;
    },
};
#####################


var afds = AFDS.new();

setlistener("/sim/signals/fdm-initialized", func {
    settimer(update_afds,5);
    print("AFDS System ... check");
});

var update_afds = func {
    afds.ap_update();

settimer(update_afds, 0);
}

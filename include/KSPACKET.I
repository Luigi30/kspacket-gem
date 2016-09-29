;KSPIO packet field offsets

;KSP_id					equ	0
KSP_AP					equ	0
KSP_PE					equ	4
KSP_SemiMajorAxis		equ	8
KSP_SemiMinorAxis		equ	12
KSP_VVI					equ	16
KSP_e					equ	20
KSP_inc					equ	24
KSP_G					equ	28
KSP_TAp					equ	32
KSP_TPe					equ	36
KSP_TrueAnomaly			equ	40
KSP_Density				equ	44
KSP_period				equ	48
KSP_RAlt				equ	52
KSP_Alt					equ	56
KSP_Vsurf				equ	60
KSP_Lat					equ	64
KSP_Lon					equ	68
KSP_LiquidFuelTot		equ	72
KSP_LiquidFuel			equ	76
KSP_OxidizerTot			equ	80
KSP_Oxidizer			equ	84
KSP_EChargeTot			equ 88
KSP_ECharge				equ	92
KSP_MonoPropTot			equ 96
KSP_MonoProp			equ 100
KSP_IntakeAirTot		equ	104
KSP_IntakeAir			equ 108
KSP_SolidFuelTot		equ	112
KSP_SolidFuel			equ	116
KSP_XenonGasTot			equ	120
KSP_XenonGas			equ	124
KSP_LiquidFuelTotS		equ	128
KSP_LiquidFuelS			equ	132
KSP_OxidizerTotS		equ	136
KSP_OxidizerS			equ	140
KSP_MissionTime			equ	144
KSP_deltaTime			equ	148
KSP_VOrbit				equ	152
KSP_MNTime				equ	156
KSP_MNDeltaV			equ	160
KSP_Pitch				equ	164
KSP_Roll				equ	168
KSP_Heading				equ	172
KSP_ActionGroups		equ	176
KSP_SOINumber			equ	178
KSP_MaxOverheat			equ	179
KSP_MachNumber			equ	180
KSP_IAS					equ	184
KSP_CurrentStage		equ	188
KSP_TotalStage			equ	189

;Orbital parameters and stuff
lbl_AP				dc.b	"Ap      : ",0
lbl_PE				dc.b	"Pe      : ",0
lbl_SemiMajorAxis	dc.b	"SMajAxis: ",0
lbl_SemiMinorAxis	dc.b	"SMinAxis: ",0
lbl_VVI				dc.b	"Vert Vel: ",0
lbl_e				dc.b	"Eccentrc: ",0
lbl_inc				dc.b	"O Inclin: ",0
lbl_G				dc.b	"Gravity : ",0
lbl_TAp				dc.b	"TimeToAp: ",0
lbl_TPe				dc.b	"TimeToPe: ",0
lbl_TrueAnomaly		dc.b	"TrueAnom: ",0
lbl_Density			dc.b	"Atm Dens: ",0
lbl_period			dc.b	"ObtPriod: ",0
lbl_RAlt			dc.b	"RadarAlt: ",0
lbl_Alt				dc.b	"Altitude: ",0
lbl_Vsurf			dc.b	"SfcVeloc: ",0
lbl_Lat				dc.b	"Sfc Lat : ",0
lbl_Lon				dc.b	"Sfc Long: ",0

;Fuel
lbl_LiquidFuelTot	dc.b	"T LqFuel: ",0
lbl_LiquidFuel		dc.b	"LqFuel  : ",0
lbl_OxidizerTot		dc.b	"T Oxidzr: ",0
lbl_Oxidizer		dc.b	"Oxidizer: ",0
lbl_EChargeTot		dc.b	"T Electr: ",0
lbl_ECharge			dc.b	"ElecChar: ",0
lbl_MonoPropTot		dc.b	"T MonoPr: ",0
lbl_MonoProp		dc.b	"MonoProp: ",0
lbl_IntakeAirTot	dc.b	"T Intake: ",0
lbl_IntakeAir		dc.b	"IntkeAir: ",0
lbl_SolidFuelTot	dc.b	"T SolidF: ",0
lbl_SolidFuel		dc.b	"Solid Fl: ",0
lbl_XenonGasTot		dc.b	"T XenonG: ",0
lbl_XenonGas		dc.b	"XenonGas: ",0
lbl_LiquidFuelTotS	dc.b	"T LqFl S: ",0
lbl_LiquidFuelS		dc.b	"LiquidFS: ",0
lbl_OxidizerTotS	dc.b	"T OxidzS: ",0
lbl_OxidizerS		dc.b	"OxidizrS: ",0

lbl_MissionTime		dc.b	"MET     : ",0
lbl_deltaTime		dc.b	"DltaTime: ",0
lbl_VOrbit			dc.b	"OrbitVel: ",0
lbl_MNTime			dc.b	"MnvrTime: ",0
lbl_MNDeltaV		dc.b	"MnvrDltV: ",0
lbl_Pitch			dc.b	"Pitch   : ",0
lbl_Roll			dc.b	"Roll    : ",0
lbl_Heading			dc.b	"Heading : ",0
lbl_ActionGroups	dc.b	"ActionGr: ",0
lbl_SOINumber		dc.b	"SOI Nmbr: ",0
lbl_MaxOverheat		dc.b	"Overheat: ",0
lbl_MachNumber		dc.b	"Mach Num: ",0
lbl_IAS				dc.b	"IAS     : ",0
lbl_CurrentStage	dc.b	"CrntStge: ",0
lbl_TotalStage		dc.b	"TotlStgs: ",0

;Units of measure
;Orbital parameters and stuff
unit_AP				dc.b	" M",0
unit_PE				dc.b	" M",0
unit_SemiMajorAxis	dc.b	" M",0
unit_SemiMinorAxis	dc.b	" M",0
unit_VVI			dc.b	" M/s",0
unit_e				dc.b	"",0
unit_inc			dc.b	" Rad",0
unit_G				dc.b	" g",0
unit_TAp			dc.b	" sec",0
unit_TPe			dc.b	" sec",0
unit_TrueAnomaly	dc.b	" Rad",0
unit_Density		dc.b	" kg/m",$FE,0 ;kg/m³
unit_period			dc.b	" sec",0
unit_RAlt			dc.b	" M",0
unit_Alt			dc.b	" M",0
unit_Vsurf			dc.b	" M/s",0
unit_Lat			dc.b	" Deg",0
unit_Lon			dc.b	" Deg",0

;Fuel
unit_LiquidFuelTot	dc.b	"",0
unit_LiquidFuel		dc.b	"",0
unit_OxidizerTot	dc.b	"",0
unit_Oxidizer		dc.b	"",0
unit_EChargeTot		dc.b	"",0
unit_ECharge		dc.b	"",0
unit_MonoPropTot	dc.b	"",0
unit_MonoProp		dc.b	"",0
unit_IntakeAirTot	dc.b	"",0
unit_IntakeAir		dc.b	"",0
unit_SolidFuelTot	dc.b	"",0
unit_SolidFuel		dc.b	"",0
unit_XenonGasTot	dc.b	"",0
unit_XenonGas		dc.b	"",0
unit_LiquidFuelTotS	dc.b	"",0
unit_LiquidFuelS	dc.b	"",0
unit_OxidizerTotS	dc.b	"",0
unit_OxidizerS		dc.b	"",0

unit_MissionTime	dc.b	"",0
unit_deltaTime		dc.b	" sec",0
unit_VOrbit			dc.b	" M/s",0
unit_MNTime			dc.b	" sec",0
unit_MNDeltaV		dc.b	" M/s",0
unit_Pitch			dc.b	" Deg",0
unit_Roll			dc.b	" Deg",0
unit_Heading		dc.b	" Deg",0
unit_ActionGroups	dc.b	"",0
unit_SOINumber		dc.b	"",0
unit_MaxOverheat	dc.b	"",0
unit_MachNumber		dc.b	" Ma",0
unit_IAS			dc.b	" M/s",0
unit_CurrentStage	dc.b	"",0
unit_TotalStage		dc.b	"",0

// Original source by Daniel Moran 2019
// Translated to verilog by Alon Levy 2021

//----------------------------------------------------------------------------------
//-- Engineer: 	Daniel Moran <dmorang@hotmail.com>
//-- Project: 	mpu6050 
//-- Description: reading raw values for mpu6050
//----------------------------------------------------------------------------------

module mpu_rg(
	input CLOCK_50,
	input reset_n,
	input en,
	inout wire I2C_SDAT,
	output I2C_SCLK,
	output reg [15:0] gx,
	output reg [15:0] gy,
	output reg [15:0] gz,
	output reg [15:0] ax,
	output reg [15:0] ay,
	output reg [15:0] az
    );

wire resetn;
reg GO;
reg SDI;
reg SCLK;
reg [15:0] data;
localparam [6:0] address = 7'b1101000; // mpu6050  default address
reg [9:0] SD_COUNTER; // VHDL used: INTEGER  RANGE 0 TO 610
reg [10:0] COUNT = 0;

    assign resetn = reset_n;

    always @(posedge CLOCK_50) begin
        COUNT<=COUNT+1;
    end
	
    always @(posedge COUNT[10], negedge resetn) begin
        if (resetn!=1) begin
			GO<=0;
        end else if (en==1) begin
			GO<=1;
        end
    end
	
	always @(posedge COUNT[10] or negedge resetn) begin
        if (resetn!=1) begin
			SD_COUNTER<=0;
        end else begin
            if (GO!=1) begin
				SD_COUNTER<=0;
            end else if (SD_COUNTER<603) begin
				SD_COUNTER<=SD_COUNTER+1;
            end else begin
				SD_COUNTER<=0;
            end
        end
    end

    //i2C OPERATION
    always @(posedge COUNT[10] or negedge resetn) begin
        if (resetn!=1) begin
			SCLK<=1;
			SDI<=1;
        end else begin
                case (SD_COUNTER)
                
    //****************************************X0*****************************************************			
                //START
                0	: 	begin
                    SDI<=1;
                    SCLK<=1;
                end
                    1	: 	SDI<=0;
                    2	: 	SCLK<=0;
        
                //DIRECCIÓN DEL ESCLAVO - ESCRITURA
                    3	: 	SDI<=address[6];
                    4	: 	SDI<=address[5];//-******************************
                    5	: 	SDI<=address[4];
                    6	: 	SDI<=address[3];
                    7	: 	SDI<=address[2];
                    8	: 	SDI<=address[1];
                    9	: 	SDI<=address[0];
                    10	: 	SDI<=0;
                    11	: 	SDI<=1'bz; // FROM Slave ACK
            
                //DIRECCIÓN DEL REGISTRO EN EL ESCLAVO (DIRECCIÓN DONDE VOY A LEER)
                    12	: 	SDI<=0;
                    13	: 	SDI<=1;
                    14	: 	SDI<=0;
                    15	: 	SDI<=0;
                    16	: 	SDI<=0;
                    17	: 	SDI<=1; //44
                    18	: 	SDI<=0;
                    19	: 	SDI<=0;
                    20	: 	SDI<=1'bz;// FROM Slave ACK
                    21,
                    
                //START
                22	: 	begin
                    SDI<=1;
                    SCLK<=1; //------------------*****************
                end
                    23	: 	SDI<=0;
                    24	: 	SCLK<=0;
                    
                //DIRECCIÓN DEL ESCLAVO - LECTURA
                    25	: 	SDI<=address[6];
                    26	: 	SDI<=address[5];//-*****************************
                    27	: 	SDI<=address[4];
                    28	: 	SDI<=address[3];
                    29	: 	SDI<=address[2];
                    30	: 	SDI<=address[1];
                    31	: 	SDI<=address[0];
                    32	: 	SDI<=1;
                    33	: 	SDI<=1'bz;//FROM Slave ACK
                    
                //DATA
                    34,
                    35	: 	data[7]<=I2C_SDAT;
                    36	: 	data[6]<=I2C_SDAT;
                    37	: 	data[5]<=I2C_SDAT;
                    38	: 	data[4]<=I2C_SDAT;
                    39	: 	data[3]<=I2C_SDAT;
                    40	: 	data[2]<=I2C_SDAT;
                    41	: 	data[1]<=I2C_SDAT;
                    42	: 	data[0]<=I2C_SDAT;
                    43	:  SDI<=0;//TO Slave ACK		
                    
                //STOP
                    44	: 	SDI<=0; //-*********************************
                    45	: 	SCLK<=1;
                    46	: 	SDI <= 1;
                    
                    
    //*****************************************X1************************************************************				
                //START
                48	: 	begin
                    SDI<=1;
                    SCLK<=1;
                end
                    49	: 	SDI<=0;
                    50	: 	SCLK<=0;
        
                //DIRECCIÓN DEL ESCLAVO - ESCRITURA
                    51	: 	SDI<=address[6];
                    52	: 	SDI<=address[5];//-******************************
                    53	: 	SDI<=address[4];
                    54	: 	SDI<=address[3];
                    55	: 	SDI<=address[2];
                    56	: 	SDI<=address[1];
                    57	: 	SDI<=address[0];
                    58	: 	SDI<=0;
                    59	: 	SDI<=1'bz;// FROM Slave ACK
            
                //DIRECCIÓN DEL REGISTRO EN EL ESCLAVO (DIRECCIÓN DONDE VOY A LEER)
                    60	: 	SDI<=0;
                    61	: 	SDI<=1;
                    62	: 	SDI<=0;
                    63	: 	SDI<=0;
                    64	: 	SDI<=0;
                    65	: 	SDI<=0;
                    66	: 	SDI<=1;
                    67	: 	SDI<=1;
                    68	: 	SDI<=1'bz;// FROM Slave ACK
                    69,
                    
                //START
                70	:	begin
                    SDI<=1;
                    SCLK<=1; //------------------*****************
                end
                    71	: 	SDI<=0;
                    72	: 	SCLK<=0;
                    
                //DIRECCIÓN DEL ESCLAVO - LECTURA
                    73	: 	SDI<=address[6];
                    74	: 	SDI<=address[5];//-*****************************
                    75	: 	SDI<=address[4];
                    76	: 	SDI<=address[3];
                    77	: 	SDI<=address[2];
                    78	: 	SDI<=address[1];
                    79	: 	SDI<=address[0];
                    80	: 	SDI<=1;
                    81	: 	SDI<=1'bz;//FROM Slave ACK
                    
                //DATA
                    82,
                    83	: 	data[15]<=I2C_SDAT;
                    84	: 	data[14]<=I2C_SDAT;
                    85	: 	data[13]<=I2C_SDAT;
                    86	: 	data[12]<=I2C_SDAT;
                    87	: 	data[11]<=I2C_SDAT;
                    88	: 	data[10]<=I2C_SDAT;
                    89	: 	data[9]<=I2C_SDAT;
                    90	: 	data[8]<=I2C_SDAT;
                    91	:  SDI<=1;//TO Slave ACK		
                    
                //STOP
                    92	: 	SDI<=0; //-*********************************
                    93	: 	begin
                        SCLK<=1;
                        gx<=data;
                    end
                    94	: 	SDI <= 1;			
                    
    //***************************************Y0***********************************************

                //START
                96	: 	begin
                    SDI<=1;
                    SCLK<=1;
                end
                    97	: 	SDI<=0;
                    98	: 	SCLK<=0;
        
                //DIRECCIÓN DEL ESCLAVO - ESCRITURA
                    99	: 	SDI<=address[6];
                    100	: 	SDI<=address[5];//-******************************
                    101	: 	SDI<=address[4];
                    102	: 	SDI<=address[3];
                    103	: 	SDI<=address[2];
                    104	: 	SDI<=address[1];
                    105	: 	SDI<=address[0];
                    106	: 	SDI<=0;
                    107	: 	SDI<=1'bz;// FROM Slave ACK
            
                //DIRECCIÓN DEL REGISTRO EN EL ESCLAVO (DIRECCIÓN DONDE VOY A LEER)
                    108	: 	SDI<=0;
                    109	: 	SDI<=1;
                    110	: 	SDI<=0;
                    111	: 	SDI<=0;//46
                    112	: 	SDI<=0;
                    113	: 	SDI<=1;
                    114	: 	SDI<=1;
                    115	: 	SDI<=0;
                    116	: 	SDI<=1'bz;// FROM Slave ACK
                    
                //START
                117,
                118	: 	begin
                    SDI<=1;
                    SCLK<=1; //------------------*****************
                end
                    119	: 	SDI<=0;
                    120	: 	SCLK<=0;
                    
                //DIRECCIÓN DEL ESCLAVO - LECTURA
                    121	: 	SDI<=address[6];
                    122	: 	SDI<=address[5];//-*****************************
                    123	: 	SDI<=address[4];
                    124	: 	SDI<=address[3];
                    125	: 	SDI<=address[2];
                    126	: 	SDI<=address[1];
                    127	: 	SDI<=address[0];
                    128	: 	SDI<=1;
                    129	: 	SDI<=1'bz;//FROM Slave ACK
                    
                //DATA
                    130,
                    131	: 	data[7]<=I2C_SDAT;
                    132	: 	data[6]<=I2C_SDAT;
                    133	: 	data[5]<=I2C_SDAT;
                    134	: 	data[4]<=I2C_SDAT;
                    135	: 	data[3]<=I2C_SDAT;
                    136	: 	data[2]<=I2C_SDAT;
                    137	: 	data[1]<=I2C_SDAT;
                    138	: 	data[0]<=I2C_SDAT;
                    139	:  SDI<=1;//TO Slave ACK		
                    
                //STOP
                    140	: 	SDI<=0; //-*********************************
                    141	: 	SCLK<=1;
                    142	: 	SDI <= 1;				
                    

    //**************************************Y1**********************************************
                
                //START
                144	: 	begin
                    SDI<=1;
                    SCLK<=1;
                end
                    145	: 	SDI<=0;
                    146	: 	SCLK<=0;
        
                //DIRECCIÓN DEL ESCLAVO - ESCRITURA
                    147	: 	SDI<=address[6];
                    148	: 	SDI<=address[5];//-******************************
                    149	: 	SDI<=address[4];
                    150	: 	SDI<=address[3];
                    151	: 	SDI<=address[2];
                    152	: 	SDI<=address[1];
                    153	: 	SDI<=address[0];
                    154	: 	SDI<=0;
                    155	: 	SDI<=1'bz;// FROM Slave ACK
            
                //DIRECCIÓN DEL REGISTRO EN EL ESCLAVO (DIRECCIÓN DONDE VOY A LEER)
                    156	: 	SDI<=0;
                    157	: 	SDI<=1;
                    158	: 	SDI<=0;
                    159	: 	SDI<=0;
                    160	: 	SDI<=0;//45
                    161	: 	SDI<=1;
                    162	: 	SDI<=0;
                    163	: 	SDI<=1;
                    164	: 	SDI<=1'bz;// FROM Slave ACK
                    
                //START
                165,
                166	: 	begin
                    SDI<=1;
                    SCLK<=1; //------------------*****************
                end
                    167	: 	SDI<=0;
                    168	: 	SCLK<=0;
                    
                //DIRECCIÓN DEL ESCLAVO - LECTURA
                    169	: 	SDI<=address[6];
                    170	: 	SDI<=address[5];//-*****************************
                    171	: 	SDI<=address[4];
                    172	: 	SDI<=address[3];
                    173	: 	SDI<=address[2];
                    174	: 	SDI<=address[1];
                    175	: 	SDI<=address[0];
                    176	: 	SDI<=1;
                    177	: 	SDI<=1'bz;//FROM Slave ACK
                    
                //DATA
                    178,
                    179	: 	data[15]<=I2C_SDAT;
                    180	: 	data[14]<=I2C_SDAT;
                    181	: 	data[13]<=I2C_SDAT;
                    182	: 	data[12]<=I2C_SDAT;
                    183	: 	data[11]<=I2C_SDAT;
                    184	: 	data[10]<=I2C_SDAT;
                    185	: 	data[9]<=I2C_SDAT;
                    186	: 	data[8]<=I2C_SDAT;
                    187	:  SDI<=1;//TO Slave ACK		
                    
                //STOP
                    188	: 	SDI<=0; //-*********************************
                    189	: 	begin
                        SCLK<=1;
                        gy<=data;
                    end
                    190	: 	SDI <= 1;
        

    //***************************************Z0***********************************************

                //START
                192	: 	begin
                    SDI<=1;
                    SCLK<=1;
                end
                    193	: 	SDI<=0;
                    194	: 	SCLK<=0;
        
                //DIRECCIÓN DEL ESCLAVO - ESCRITURA
                    195	: 	SDI<=address[6];
                    196	: 	SDI<=address[5];//-******************************
                    197	: 	SDI<=address[4];
                    198	: 	SDI<=address[3];
                    199	: 	SDI<=address[2];
                    200	: 	SDI<=address[1];
                    201	: 	SDI<=address[0];
                    202	: 	SDI<=0;
                    203	: 	SDI<=1'bz;// FROM Slave ACK
            
                //DIRECCIÓN DEL REGISTRO EN EL ESCLAVO (DIRECCIÓN DONDE VOY A LEER)
                    204	: 	SDI<=0;
                    205	: 	SDI<=1;
                    206	: 	SDI<=0;
                    207	: 	SDI<=0;
                    208	: 	SDI<=1;
                    209	: 	SDI<=0;//48
                    210	: 	SDI<=0;
                    211	: 	SDI<=0;
                    212	: 	SDI<=1'bz;// FROM Slave ACK
                    
                //START
                213,
                214	: 	begin
                    SDI<=1;
                    SCLK<=1; //------------------*****************
                end
                    215	: 	SDI<=0;
                    216	: 	SCLK<=0;
                    
                //DIRECCIÓN DEL ESCLAVO - LECTURA
                    217	: 	SDI<=address[6];
                    218	: 	SDI<=address[5];//-******************************
                    219	: 	SDI<=address[4];
                    220	: 	SDI<=address[3];
                    221	: 	SDI<=address[2];
                    222	: 	SDI<=address[1];
                    223	: 	SDI<=address[0];
                    224	: 	SDI<=1;
                    225	: 	SDI<=1'bz;//FROM Slave ACK
                    
                //DATA
                    226,
                    227	: 	data[7]<=I2C_SDAT;
                    228	: 	data[6]<=I2C_SDAT;
                    229	: 	data[5]<=I2C_SDAT;
                    230	: 	data[4]<=I2C_SDAT;
                    231	: 	data[3]<=I2C_SDAT;
                    232	: 	data[2]<=I2C_SDAT;
                    233	: 	data[1]<=I2C_SDAT;
                    234	: 	data[0]<=I2C_SDAT;
                    235	:  SDI<=1;//TO Slave ACK		
                    
                //STOP
                    236	: 	SDI<=0; //-*********************************
                    237	: 	SCLK<=1;
                    238	: 	SDI <= 1;
                    

    //***************************************Z1***********************************************

                //START
                239	: 	begin
                    SDI<=1;
                    SCLK<=1;
                end
                    240	: 	SDI<=0;
                    241	: 	SCLK<=0;
        
                //DIRECCIÓN DEL ESCLAVO - ESCRITURA
                    242	: 	SDI<=address[6];
                    243	: 	SDI<=address[5];//-******************************
                    244	: 	SDI<=address[4];
                    245	: 	SDI<=address[3];
                    246	: 	SDI<=address[2];
                    247	: 	SDI<=address[1];
                    248	: 	SDI<=address[0];
                    249	: 	SDI<=0;
                    250	: 	SDI<=1'bz;// FROM Slave ACK
            
                //DIRECCIÓN DEL REGISTRO EN EL ESCLAVO (DIRECCIÓN DONDE VOY A LEER)
                    251	: 	SDI<=0;
                    252	: 	SDI<=1;
                    253	: 	SDI<=0;
                    254	: 	SDI<=0;
                    255	: 	SDI<=0;
                    256	: 	SDI<=1;//47
                    257	: 	SDI<=1;
                    258	: 	SDI<=1;
                    259	: 	SDI<=1'bz;// FROM Slave ACK
                    
                //START
                260,
                261	: 	begin
                    SDI<=1;
                    SCLK<=1; //------------------*****************
                end
                    262	: 	SDI<=0;
                    263	: 	SCLK<=0;
                    
                //DIRECCIÓN DEL ESCLAVO - LECTURA
                    264	: 	SDI<=address[6];
                    265	: 	SDI<=address[5];//-******************************
                    266	: 	SDI<=address[4];
                    267	: 	SDI<=address[3];
                    268	: 	SDI<=address[2];
                    269	: 	SDI<=address[1];
                    270	: 	SDI<=address[0];
                    271	: 	SDI<=1;
                    272	: 	SDI<=1'bz;//FROM Slave ACK
                    
                //DATA
                    273,
                    274	: 	data[15]<=I2C_SDAT;
                    275	: 	data[14]<=I2C_SDAT;
                    276	: 	data[13]<=I2C_SDAT;
                    277	: 	data[12]<=I2C_SDAT;
                    278	: 	data[11]<=I2C_SDAT;
                    279	: 	data[10]<=I2C_SDAT;
                    280	: 	data[9]<=I2C_SDAT;
                    281	: 	data[8]<=I2C_SDAT;
                    282	:  SDI<=1;//TO Slave ACK		
                    
                //STOP
                    283	: 	SDI<=0; //-*********************************
                    284	: 	begin
                        SCLK<=1;
                        gz<=data;
                    end
                    285	: 	SDI <= 1;	
        //---------------------------------------------------------	
    //***************************************ax1***********************************************

                //START
                286	: 	begin
                    SDI<=1;
                    SCLK<=1;
                end
                    287	: 	SDI<=0;
                    288	: 	SCLK<=0;
        
                //DIRECCIÓN DEL ESCLAVO - ESCRITURA
                    289	: 	SDI<=address[6];
                    290	: 	SDI<=address[5];//-******************************
                    291	: 	SDI<=address[4];
                    292	: 	SDI<=address[3];
                    293	: 	SDI<=address[2];
                    294	: 	SDI<=address[1];
                    295	: 	SDI<=address[0];
                    296	: 	SDI<=0;
                    297	: 	SDI<=1'bz;// FROM Slave ACK
            
                //DIRECCIÓN DEL REGISTRO EN EL ESCLAVO (DIRECCIÓN DONDE VOY A LEER)
                    298	: 	SDI<=0;
                    299	: 	SDI<=0;
                    300	: 	SDI<=1;
                    301	: 	SDI<=1;
                    302	: 	SDI<=1;
                    303	: 	SDI<=0;
                    304	: 	SDI<=1;
                    305	: 	SDI<=1;
                    306	: 	SDI<=1'bz;// FROM Slave ACK
                    307,
                    
                //START
                308	: 	begin
                    SDI<=1;
                    SCLK<=1; //------------------*****************
                end
                    309	: 	SDI<=0;
                    310	: 	SCLK<=0;
                    
                //DIRECCIÓN DEL ESCLAVO - LECTURA
                    311	: 	SDI<=address[6];
                    312	: 	SDI<=address[5];//-******************************
                    313	: 	SDI<=address[4];
                    314	: 	SDI<=address[3];
                    315	: 	SDI<=address[2];
                    316	: 	SDI<=address[1];
                    317	: 	SDI<=address[0];
                    318	: 	SDI<=1;
                    319	: 	SDI<=1'bz;//FROM Slave ACK
                    
                //DATA
                    320,
                    321	: 	data[15]<=I2C_SDAT;
                    322	: 	data[14]<=I2C_SDAT;
                    323	: 	data[13]<=I2C_SDAT;
                    324	: 	data[12]<=I2C_SDAT;
                    325	: 	data[11]<=I2C_SDAT;
                    326	: 	data[10]<=I2C_SDAT;
                    327	: 	data[9]<=I2C_SDAT;
                    328	: 	data[8]<=I2C_SDAT;
                    329	:  SDI<=1;//TO Slave ACK		
                    
                //STOP
                    330	: 	SDI<=0; //-*********************************
                    331	: 	SCLK<=1;
                    334	: 	SDI <= 1;		
                    //------------------------------------------------------
                        //---------------------------------------------------------	
    //***************************************ax0***********************************************

                //START
                335	: 	begin
                    SDI<=1;
                    SCLK<=1;
                end
                    336	: 	SDI<=0;
                    337	: 	SCLK<=0;
        
                //DIRECCIÓN DEL ESCLAVO - ESCRITURA
                    338	: 	SDI<=address[6];
                    339	: 	SDI<=address[5];//-******************************
                    340	: 	SDI<=address[4];
                    341	: 	SDI<=address[3];
                    342	: 	SDI<=address[2];
                    343	: 	SDI<=address[1];
                    344	: 	SDI<=address[0];
                    345	: 	SDI<=0;
                    346	: 	SDI<=1'bz;// FROM Slave ACK
            
                //DIRECCIÓN DEL REGISTRO EN EL ESCLAVO (DIRECCIÓN DONDE VOY A LEER)
                    347	: 	SDI<=0;
                    348	: 	SDI<=0;
                    349	: 	SDI<=1;
                    350	: 	SDI<=1;
                    351	: 	SDI<=1;
                    352	: 	SDI<=1;
                    353	: 	SDI<=0;
                    354	: 	SDI<=0;
                    355	: 	SDI<=1'bz;// FROM Slave ACK
                    356,
                    
                //START
                357	: 	begin
                    SDI<=1;
                    SCLK<=1; //------------------*****************
                end
                    358	: 	SDI<=0;
                    359	: 	SCLK<=0;
                    
                //DIRECCIÓN DEL ESCLAVO - LECTURA
                    360	: 	SDI<=address[6];
                    361	: 	SDI<=address[5];//-******************************
                    362	: 	SDI<=address[4];
                    363	: 	SDI<=address[3];
                    364	: 	SDI<=address[2];
                    365	: 	SDI<=address[1];
                    366	: 	SDI<=address[0];
                    367	: 	SDI<=1;
                    368	: 	SDI<=1'bz;//FROM Slave ACK
                    
                //DATA
                    369, 
                    370	: 	data[7]<=I2C_SDAT;
                    371	: 	data[6]<=I2C_SDAT;
                    372	: 	data[5]<=I2C_SDAT;
                    373	: 	data[4]<=I2C_SDAT;
                    374	: 	data[3]<=I2C_SDAT;
                    375	: 	data[2]<=I2C_SDAT;
                    376	: 	data[1]<=I2C_SDAT;
                    377	: 	data[0]<=I2C_SDAT;
                    378	:  SDI<=1;//TO Slave ACK		
                    
                //STOP
                    379	: 	SDI<=0; //-*********************************
                    380	: 	begin
                        SCLK<=1;
                        ax<=data;
                    end
                    381	: 	SDI <= 1;		
                    //------------------------------------------------------
                        //---------------------------------------------------------	
    //***************************************ay1***********************************************

                //START
                382	: 	begin
                    SDI<=1;
                    SCLK<=1;
                end
                    383	: 	SDI<=0;
                    384	: 	SCLK<=0;
        
                //DIRECCIÓN DEL ESCLAVO - ESCRITURA
                    385	: 	SDI<=address[6];
                    386	: 	SDI<=address[5];//-******************************
                    387	: 	SDI<=address[4];
                    388	: 	SDI<=address[3];
                    389	: 	SDI<=address[2];
                    390	: 	SDI<=address[1];
                    391	: 	SDI<=address[0];
                    392	: 	SDI<=0;
                    393	: 	SDI<=1'bz;// FROM Slave ACK
            
                //DIRECCIÓN DEL REGISTRO EN EL ESCLAVO (DIRECCIÓN DONDE VOY A LEER)
                    394	: 	SDI<=0;
                    395	: 	SDI<=0;
                    396	: 	SDI<=1;
                    397	: 	SDI<=1;
                    398	: 	SDI<=1;
                    399	: 	SDI<=1;
                    400	: 	SDI<=0;
                    401	: 	SDI<=1;
                    402	: 	SDI<=1'bz;// FROM Slave ACK
                    403,
                    
                //START
                404	: 	begin
                    SDI<=1;
                    SCLK<=1; //------------------*****************
                end
                    405	: 	SDI<=0;
                    406	: 	SCLK<=0;
                    
                //DIRECCIÓN DEL ESCLAVO - LECTURA
                    407	: 	SDI<=address[6];
                    408	: 	SDI<=address[5];//-******************************
                    409	: 	SDI<=address[4];
                    410	: 	SDI<=address[3];
                    411	: 	SDI<=address[2];
                    412	: 	SDI<=address[1];
                    413	: 	SDI<=address[0];
                    414	: 	SDI<=1;
                    415	: 	SDI<=1'bz;//FROM Slave ACK
                    
                //DATA
                    416,
                    417	: 	data[15]<=I2C_SDAT;
                    418	: 	data[14]<=I2C_SDAT;
                    419	: 	data[13]<=I2C_SDAT;
                    420	: 	data[12]<=I2C_SDAT;
                    421	: 	data[11]<=I2C_SDAT;
                    422	: 	data[10]<=I2C_SDAT;
                    423	: 	data[9]<=I2C_SDAT;
                    424	: 	data[8]<=I2C_SDAT;
                    425	:  SDI<=1;//TO Slave ACK		
                    
                //STOP
                    426	: 	SDI<=0; //-*********************************
                    427	: 	SCLK<=1;
                    428	: 	SDI <= 1;		
                    //------------------------------------------------------
                        //---------------------------------------------------------	
    //***************************************ay0***********************************************

                //START
                429	: 	begin
                    SDI<=1;
                    SCLK<=1;
                end
                    430	: 	SDI<=0;
                    431	: 	SCLK<=0;
        
                //DIRECCIÓN DEL ESCLAVO - ESCRITURA
                    432	: 	SDI<=address[6];
                    433	: 	SDI<=address[5];//-******************************
                    434	: 	SDI<=address[4];
                    435	: 	SDI<=address[3];
                    436	: 	SDI<=address[2];
                    437	: 	SDI<=address[1];
                    438	: 	SDI<=address[0];
                    439	: 	SDI<=0;
                    440	: 	SDI<=1'bz;// FROM Slave ACK
            
                //DIRECCIÓN DEL REGISTRO EN EL ESCLAVO (DIRECCIÓN DONDE VOY A LEER)
                    441	: 	SDI<=0;
                    442	: 	SDI<=0;
                    443	: 	SDI<=1;
                    444	: 	SDI<=1;
                    445	: 	SDI<=1;
                    446	: 	SDI<=1;
                    447	: 	SDI<=1;
                    448	: 	SDI<=0;
                    449	: 	SDI<=1'bz;// FROM Slave ACK
                    450,
                    
                //START
                451	: 	begin
                    SDI<=1;
                    SCLK<=1; //------------------*****************
                end
                    452	: 	SDI<=0;
                    453	: 	SCLK<=0;
                    
                //DIRECCIÓN DEL ESCLAVO - LECTURA
                    454	: 	SDI<=address[6];
                    455	: 	SDI<=address[5];//-******************************
                    456	: 	SDI<=address[4];
                    457	: 	SDI<=address[3];
                    458	: 	SDI<=address[2];
                    459	: 	SDI<=address[1];
                    460	: 	SDI<=address[0];
                    461	: 	SDI<=1;
                    462	: 	SDI<=1'bz;//FROM Slave ACK
                    
                //DATA
                    463,
                    464	: 	data[7]<=I2C_SDAT;
                    465	: 	data[6]<=I2C_SDAT;
                    466	: 	data[5]<=I2C_SDAT;
                    467	: 	data[4]<=I2C_SDAT;
                    468	: 	data[3]<=I2C_SDAT;
                    469	: 	data[2]<=I2C_SDAT;
                    470	: 	data[1]<=I2C_SDAT;
                    471	: 	data[0]<=I2C_SDAT;
                    472	:  SDI<=1;//TO Slave ACK		
                    
                //STOP
                    473	: 	SDI<=0; //-*********************************
                    474	: 	begin
                        SCLK<=1;
                        ay<=data;
                    end
                    475	: 	SDI <= 1;		
                    //------------------------------------------------------
                    
                                        //---------------------------------------------------------	
    //***************************************az1***********************************************

                //START
                476	: 	begin
                    SDI<=1;
                    SCLK<=1;
                end
                    477	: 	SDI<=0;
                    478	: 	SCLK<=0;
        
                //DIRECCIÓN DEL ESCLAVO - ESCRITURA
                    479	: 	SDI<=address[6];
                    480	: 	SDI<=address[5];//-******************************
                    481	: 	SDI<=address[4];
                    482	: 	SDI<=address[3];
                    483	: 	SDI<=address[2];
                    484	: 	SDI<=address[1];
                    485	: 	SDI<=address[0];
                    486	: 	SDI<=0;
                    487	: 	SDI<=1'bz;// FROM Slave ACK
            
                //DIRECCIÓN DEL REGISTRO EN EL ESCLAVO (DIRECCIÓN DONDE VOY A LEER)
                    488	: 	SDI<=0;
                    489	: 	SDI<=0;
                    490	: 	SDI<=1;
                    491	: 	SDI<=1;
                    492	: 	SDI<=1;
                    493	: 	SDI<=1;
                    494	: 	SDI<=1;
                    495	: 	SDI<=1;
                    496	: 	SDI<=1'bz;// FROM Slave ACK
                    497,
                    
                //START
                498	: 	begin
                    SDI<=1;
                    SCLK<=1; //------------------*****************
                end
                    499	: 	SDI<=0;
                    500	: 	SCLK<=0;
                    
                //DIRECCIÓN DEL ESCLAVO - LECTURA
                    501	: 	SDI<=address[6];
                    502	: 	SDI<=address[5];//-******************************
                    503	: 	SDI<=address[4];
                    504	: 	SDI<=address[3];
                    505	: 	SDI<=address[2];
                    506	: 	SDI<=address[1];
                    507	: 	SDI<=address[0];
                    508	: 	SDI<=1;
                    509	: 	SDI<=1'bz;//FROM Slave ACK
                    
                //DATA
                    510,
                    511	: 	data[15]<=I2C_SDAT;
                    512	: 	data[14]<=I2C_SDAT;
                    513	: 	data[13]<=I2C_SDAT;
                    514	: 	data[12]<=I2C_SDAT;
                    515	: 	data[11]<=I2C_SDAT;
                    516	: 	data[10]<=I2C_SDAT;
                    517	: 	data[9]<=I2C_SDAT;
                    518	: 	data[8]<=I2C_SDAT;
                    519	:  SDI<=1;//TO Slave ACK		
                    
                //STOP
                    520	: 	SDI<=0; //-*********************************
                    521	: 	SCLK<=1;
                    522	: 	SDI <= 1;		
                    //------------------------------------------------------
                    
                                        //---------------------------------------------------------	
    //***************************************az0***********************************************

                //START
                523	: 	begin
                    SDI<=1;
                    SCLK<=1;
                end
                    524	: 	SDI<=0;
                    525	: 	SCLK<=0;
        
                //DIRECCIÓN DEL ESCLAVO - ESCRITURA
                    526	: 	SDI<=address[6];
                    527	: 	SDI<=address[5];//-******************************
                    528	: 	SDI<=address[4];
                    529	: 	SDI<=address[3];
                    530	: 	SDI<=address[2];
                    531	: 	SDI<=address[1];
                    532	: 	SDI<=address[0];
                    533	: 	SDI<=0;
                    534	: 	SDI<=1'bz;// FROM Slave ACK
            
                //DIRECCIÓN DEL REGISTRO EN EL ESCLAVO (DIRECCIÓN DONDE VOY A LEER)
                    535	: 	SDI<=0;
                    536	: 	SDI<=1;
                    537	: 	SDI<=0;
                    538	: 	SDI<=0;
                    539	: 	SDI<=0;
                    540	: 	SDI<=0;
                    541	: 	SDI<=0;
                    542	: 	SDI<=0;
                    543	: 	SDI<=1'bz;// FROM Slave ACK
                    
                //START
                544,
                545	: 	begin
                    SDI<=1;
                    SCLK<=1; //------------------*****************
                end
                    546	: 	SDI<=0;
                    547	: 	SCLK<=0;
                    
                //DIRECCIÓN DEL ESCLAVO - LECTURA
                    548	: 	SDI<=address[6];
                    549	: 	SDI<=address[5];//-******************************
                    550	: 	SDI<=address[4];
                    551	: 	SDI<=address[3];
                    552	: 	SDI<=address[2];
                    553	: 	SDI<=address[1];
                    554	: 	SDI<=address[0];
                    555	: 	SDI<=1;
                    556	: 	SDI<=1'bz;//FROM Slave ACK
                    
                //DATA
                    557,
                    558	: 	data[7]<=I2C_SDAT;
                    559	: 	data[6]<=I2C_SDAT;
                    560	: 	data[5]<=I2C_SDAT;
                    561	: 	data[4]<=I2C_SDAT;
                    562	: 	data[3]<=I2C_SDAT;
                    563	: 	data[2]<=I2C_SDAT;
                    564	: 	data[1]<=I2C_SDAT;
                    565	: 	data[0]<=I2C_SDAT;
                    566	:  SDI<=1;//TO Slave ACK		
                    
                //STOP
                    567	: 	SDI<=0; //-*********************************
                    568	: 	begin
                        SCLK<=1;
                        az<=data;
                    end
                    569	: 	SDI <= 1;		
                    //------------------------------------------------------
                    //*********************************REGISTRO (0X6b)************************************************************			
                //START
                570	: 	begin
                    SDI<=1;
                    SCLK<=1;
                end
                    571	: 	SDI<=0;
                    572	: 	SCLK<=0;
        
                //DIRECCIÓN DEL ESCLAVO  ESCRITURA
                    573	: 	SDI<=address[6];
                    574	: 	SDI<=address[5];//-******************************
                    575	: 	SDI<=address[4];
                    576	: 	SDI<=address[3];
                    577	: 	SDI<=address[2];
                    578	: 	SDI<=address[1];
                    579	: 	SDI<=address[0];
                    580	: 	SDI<=0;
                    581	: 	SDI<=1'bz;//Slave ACK
            
                //DIRECCIÓN DEL REGISTRO EN EL ESCLAVO (DIRECCIÓN DONDE VOY A ESCRIBIR)
                    582	: 	SDI<=0;
                    583	: 	SDI<=1;
                    584	: 	SDI<=1;
                    585	: 	SDI<=0;
                    586	: 	SDI<=1;
                    587	: 	SDI<=0;
                    588	: 	SDI<=1;
                    589	: 	SDI<=1;//(0X6b)
                    590	: 	SDI<=1'bz;//Slave ACK
                    
                //DATA
                    591	: 	SDI<=0;
                    592	: 	SDI<=0;
                    593	: 	SDI<=0;
                    594	: 	SDI<=0;
                    595	: 	SDI<=0;
                    596	: 	SDI<=0;
                    597	: 	SDI<=0;
                    598	: 	SDI<=0;
                    599	: 	SDI<=1'bz;//Slave ACK

                //STOP
                    600	: 		SDI<=0;//****************************************
                    601	: 	  SCLK<=1; 
                    602	: 	 SDI <= 1;
                    //----------------------------------------------------------------------
                    
                    default: begin
                        SDI<=1;
                        SCLK<=1;
                    end

                endcase;
            end
        end
        assign I2C_SCLK = ( ((SD_COUNTER >= 4) && (SD_COUNTER <= 22)) || ((SD_COUNTER >= 26) && (SD_COUNTER <= 44))
								|| ((SD_COUNTER >= 52) && (SD_COUNTER <= 70)) || ((SD_COUNTER >= 74) && (SD_COUNTER <= 92))
								|| ((SD_COUNTER >= 100) && (SD_COUNTER <= 118)) || ((SD_COUNTER >= 122) && (SD_COUNTER <= 140))
								|| ((SD_COUNTER >= 148) && (SD_COUNTER <= 166)) || ((SD_COUNTER >= 170) && (SD_COUNTER <= 188))
								|| ((SD_COUNTER >= 196) && (SD_COUNTER <= 214)) || ((SD_COUNTER >= 218) && (SD_COUNTER <= 236))
								|| ((SD_COUNTER >= 243) && (SD_COUNTER <= 261)) || ((SD_COUNTER >= 265) && (SD_COUNTER <= 283))
								|| ((SD_COUNTER >= 290) && (SD_COUNTER <= 308)) || ((SD_COUNTER >= 312) && (SD_COUNTER <= 330))
								|| ((SD_COUNTER >= 339) && (SD_COUNTER <= 357)) || ((SD_COUNTER >= 361) && (SD_COUNTER <= 379))
								|| ((SD_COUNTER >= 386) && (SD_COUNTER <= 404)) || ((SD_COUNTER >= 408) && (SD_COUNTER <= 426))
								|| ((SD_COUNTER >= 433) && (SD_COUNTER <= 451)) || ((SD_COUNTER >= 455) && (SD_COUNTER <= 473))
								|| ((SD_COUNTER >= 480) && (SD_COUNTER <= 498)) || ((SD_COUNTER >= 502) && (SD_COUNTER <= 520))
								|| ((SD_COUNTER >= 527) && (SD_COUNTER <= 545)) || ((SD_COUNTER >= 549) && (SD_COUNTER <= 567))
								|| ((SD_COUNTER >= 574) && (SD_COUNTER <= 600))
                                ) ? !COUNT[10] : SCLK;
	assign I2C_SDAT = SDI;
endmodule


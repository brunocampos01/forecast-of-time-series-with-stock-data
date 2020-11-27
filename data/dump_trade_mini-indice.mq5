#property copyright "Bruno Campos"
#property link      "www.gihub.com/brunocampos01/tcc"
#property version   "1.00"
#property script_show_inputs

input datetime 	deals_from 	= D'2019.01.01 00:00';		// Start Date
input datetime 	deals_to   	= D'2030.12.5 00:00';		// End date
input string 	FileName  	= "trades_mini-indice.csv";	// File name to export data

void OnStart() 
{
	Print("##### START SCRIPT ####");
//---
	
	if ( deals_from >= deals_to ) 
	{
		Alert ("ERROR: The start date is earlier than the end date");
		return;
	}
	
	// Creating the file handle for the output file (WRITE)
	int file_handle = FileOpen(FileName,FILE_TXT|FILE_WRITE);
	string data = NULL;
	
	// Showing an error message if something goes wrong with creating the file handle
	if(file_handle == INVALID_HANDLE)
	{
		Alert("File open failed, error ",_LastError);
		return;
	}
	
	// Load into memory the trade history between the dates
	if ( HistorySelect( deals_from, deals_to ))
	{
		// Preparing the column anmes
		data  = "Position ID"			+"\t";
		data += "Type"					+"\t";
		data += "Symbol"				+"\t";
		data += "Volume"				+"\t";
		data += "Open Date/Time"		+"\t";
		data += "Open Price"			+"\t";
		data += "Close Date/Time"		+"\t";
		data += "Close Price"			+"\t";
		data += "TakeProfit"			+"\t";
		data += "StopLoss"				+"\t";
		data += "Position PnL"			+"\t";
		data += "Position PnL (points)"	+"\t";
		data += "Swap"					+"\t";
		data += "Swap (points)"			+"\t";
		data += "Commission"			+"\t";
		data += "Commission (points)"	+"\t";
		data += "Total PnL"				+"\t";
		data += "Total PnL (points)"	+"\t";
		data += "MagicNumber"			+"\t";
		data += "Comment"				+"\t";
		data += "Deal in ID"			+"\t";
		data += "Deal out ID"			+"\t";
		
		// Writting the column name in the file
		FileWrite(file_handle, data );

		ulong deal_in_ticket=-1;
		bool IsDupe;

		// Loading all Deals in memory
		int deals_total = HistoryDealsTotal();
		
		// Define the array to store positions ID
		ulong arr_Positions[];
		ArrayResize( arr_Positions, deals_total, true );
		
		// We loop through all deals loaded in memory to stored the POSITION_IDENTIFIER into an array for later use
		for( int i = 0; i < deals_total; i++ )
			
			// For each DEAL load in memory we filter for the DEAL_IN only, then we will store the POSITION_IDENTIFIER
			if( ( deal_in_ticket = HistoryDealGetTicket( i )) > 0 && HistoryDealGetInteger(deal_in_ticket, DEAL_ENTRY) == DEAL_ENTRY_IN ) 
	        {				
				// Obtain the POSITION IDENTIFIER
				ulong  _posID=HistoryDealGetInteger(deal_in_ticket,DEAL_POSITION_ID);
				
				IsDupe = false;
				
				// We loop through already collected data seeking for duplicates
				// If a duplicate is found the loop is stoped
				for ( int j = i; j >= 0; j-- )
				{
					if ( arr_Positions[j] == _posID ) 
					{
						IsDupe = true;	// a duplicate was found
						break;
					}
				}

				if ( IsDupe ) continue;  // If a duplicate was found, the loop jumps to next iteration
				
				arr_Positions[i] = _posID;  // If no duplicate found, we store the _posID into the array
			}
			
		int _history_deals_by_pos = -1;
		int _history_order_by_pos = -1;
		int size = ArraySize(arr_Positions);
		int cnt=0;
			
		// Now that we got all POSITION IDENTIFIER in our array, we will process them
		for( int i = 0; i < size ; i++ )
		{
			// Declaring all used variables
			long _direction=-1,_magic=-1;
			ulong _posID=0, deal_ticket, order_ticket;
			double open_price=-1, close_price=-1, deal_volume=0, _tp=-1, _sl=-1, _profit=0, _swap=0, _commission=0;
			string _comment=NULL, _symbol=NULL,_deal_in_ID=NULL, _deal_out_ID=NULL,close_time=NULL, open_time=NULL;

			// Loading DEALs and ORDERS belonging to one POSITION
			if ( HistorySelectByPosition(arr_Positions[i]) )
			{
				// If there is not POS_ID move to next iteration
				if ( arr_Positions[i] == 0 ) continue;
				
				cnt++;

				// Counting the DEALS and ORDERS with the same POS_ID
				_history_deals_by_pos = HistoryDealsTotal();
				_history_order_by_pos = HistoryOrdersTotal();				

				// Looping through each DEAL
				for( int j = 0; j <= _history_deals_by_pos; j++ )
				{
					// Get the DEAl ticket for this round
					deal_ticket=HistoryDealGetTicket( j );
					
					// If there is no ticket we move to next iteration
					if ( deal_ticket == 0 ) continue;
					
					// Collecting information of if the DEAL is a DEAL_OUT or DEAL_INOUT or DEAL_OUT_BY
					if ( HistoryDealGetInteger(deal_ticket, DEAL_ENTRY) != DEAL_ENTRY_IN ) 
					{
						close_time	= TimeToString( HistoryDealGetInteger(deal_ticket, DEAL_TIME),TIME_DATE)+" "+TimeToString( HistoryDealGetInteger(deal_ticket, DEAL_TIME),TIME_SECONDS);
						close_price	= HistoryDealGetDouble (deal_ticket, DEAL_PRICE);
						deal_volume	+= HistoryDealGetDouble (deal_ticket, DEAL_VOLUME);
						_deal_out_ID+= IntegerToString( deal_ticket)+";";
					}
					
					// Collecting information of if the DEAL is DEAL_IN
					if ( HistoryDealGetInteger(deal_ticket, DEAL_ENTRY)== DEAL_ENTRY_IN  ) 
					{
						_direction	= HistoryDealGetInteger(deal_ticket, DEAL_TYPE);
						open_time	= TimeToString( HistoryDealGetInteger(deal_ticket, DEAL_TIME),TIME_DATE)+" "+TimeToString( HistoryDealGetInteger(deal_ticket, DEAL_TIME),TIME_SECONDS);
						open_price	= HistoryDealGetDouble (deal_ticket, DEAL_PRICE);
						_deal_in_ID+= IntegerToString( deal_ticket)+";";
					}
					
					_posID		 = HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID);
					_magic		 = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
					_symbol		 = HistoryDealGetString (deal_ticket, DEAL_SYMBOL);
					_commission	+= HistoryDealGetDouble (deal_ticket, DEAL_COMMISSION);
					_swap		+= HistoryDealGetDouble (deal_ticket, DEAL_SWAP);
					_profit		+= HistoryDealGetDouble (deal_ticket, DEAL_PROFIT);
					_comment	+= HistoryDealGetString (deal_ticket, DEAL_COMMENT)+"/";
				}
	
				// Looping through all the ORDERS
				for( int j = _history_order_by_pos; j > 0; j-- )
				{
					order_ticket = HistoryOrderGetTicket( j );
					if ( order_ticket == 0 ) continue;
					
					HistoryOrderGetDouble( order_ticket, ORDER_TP, _tp );
					HistoryOrderGetDouble( order_ticket, ORDER_SL, _sl );
				}
	
				// Replacing all the dots (.) with dashes (-) for Excel to recognise the date format automatically
				StringReplace( close_time, ".", "-");
				StringReplace( open_time,  ".", "-");
	
				double tick_value_profit 	= SymbolInfoDouble (_symbol, SYMBOL_TRADE_TICK_VALUE_PROFIT);
				double tick_value_loss 		= SymbolInfoDouble (_symbol, SYMBOL_TRADE_TICK_VALUE_LOSS);
				double tick_size  			= SymbolInfoDouble (_symbol, SYMBOL_TRADE_TICK_SIZE);
				double points	  			= SymbolInfoDouble (_symbol, SYMBOL_POINT);
				int    decimals		   = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
	
				double total_profit 		= _profit+_swap+_commission;
				double tick_value = ( _profit < 0 )? tick_value_loss : tick_value_profit;
												
				// Preparing the data
				data  = IntegerToString(_posID)+"\t";
				data += GetDealTypeDescr(int(_direction))+"\t";
				data += _symbol+"\t";
				data += DoubleToString(deal_volume,decimals)+"\t";
				data += open_time+"\t";
				data += DoubleToString(open_price,decimals)+"\t";
				data += close_time+"\t";
				data += DoubleToString(close_price,decimals)+"\t";
				data += DoubleToString(_tp,decimals)+"\t";
				data += DoubleToString(_sl,decimals)+"\t";
				data += DoubleToString(_profit,2)+"\t";
				data += DoubleToString(_profit / ( deal_volume / tick_size * tick_value ) / points, 2 )+"\t";
				data += DoubleToString(_swap,2)+"\t";
				data += DoubleToString(_swap / ( deal_volume / tick_size * tick_value ) / points, 2 )+"\t";
				data += DoubleToString(_commission,2)+"\t";
				data += DoubleToString(_commission / ( deal_volume / tick_size * tick_value ) / points, 2 )+"\t";
				data += DoubleToString(total_profit,2)+"\t";
				data += DoubleToString(total_profit / ( deal_volume / tick_size * tick_value ) / points, 2 )+"\t";
				data += IntegerToString(_magic)+"\t";
				data += _comment+"\t";
				data += _deal_in_ID+"\t";
				data += _deal_out_ID+"\t";
											
				// Writting data to the file
				FileWrite( file_handle,data);
								
			}//end HistorySelectByPosition		
		}//end for (i)
	printf("I found %d positions in hisotry", cnt );
	}//end if select history
			
	// Closing file
	FileClose(file_handle);

//---  
	Print("##### END SCRIPT ####");
}

string GetDealTypeDescr(int deal_type)
{
	string descr;

	switch(deal_type)
	{
		case DEAL_TYPE_BALANCE:                  return ("balance");
		case DEAL_TYPE_CREDIT:                   return ("credit");
		case DEAL_TYPE_CHARGE:                   return ("charge");
		case DEAL_TYPE_CORRECTION:               return ("correction");
		case DEAL_TYPE_BUY:                      return ("buy");
		case DEAL_TYPE_SELL:                     return ("sell");
		case DEAL_TYPE_BONUS:                    return ("bonus");
		case DEAL_TYPE_COMMISSION:               return ("additional commission");
		case DEAL_TYPE_COMMISSION_DAILY:         return ("daily commission");
		case DEAL_TYPE_COMMISSION_MONTHLY:       return ("monthly commision");
		case DEAL_TYPE_COMMISSION_AGENT_DAILY:   return ("Daily agent commission");
		case DEAL_TYPE_COMMISSION_AGENT_MONTHLY: return ("Monthly agent commission");
		case DEAL_TYPE_INTEREST:                 return ("interest rate");
		case DEAL_TYPE_BUY_CANCELED:             return ("buy canceled");
		case DEAL_TYPE_SELL_CANCELED:            return ("sell canceled");
	}
	
	return(descr);
}

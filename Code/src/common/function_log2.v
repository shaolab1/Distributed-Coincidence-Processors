`ifndef _FUNC_LOG2_

    `define _FUNC_LOG2_
	
    // y = log2(x)
	function integer log2;
	  input integer x;
		begin
		  x = x-1;
		  for(log2=0; x>0; log2=log2+1)
			 x = x>>1;
		end
	endfunction

`endif 
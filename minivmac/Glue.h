//
//  Glue.h
//  minivmac
//
//  Created by Josh on 2/23/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

GLOBALFUNC tMacErr vSonyTransfer(blnr IsWrite, ui3p Buffer,
                                 tDrive Drive_No, ui5r Sony_Start, ui5r Sony_Count,
                                 ui5r *Sony_ActCount);
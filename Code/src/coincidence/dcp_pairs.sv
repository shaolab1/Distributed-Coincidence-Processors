parameter int PAIR_NUM = 432;
parameter int COINCIDENCE_PAIR_MAT[PAIR_NUM][2] = '{'{0,3},'{0,4},'{0,5},'{0,6},'{0,7},'{0,8},'{0,9},'{0,10},'{0,11},'{0,12},'{0,13},'{0,14},'{0,15},'{0,16},'{0,17},'{0,18},'{0,19},'{0,20},'{0,21},'{0,22},'{0,23},'{0,24},'{0,25},'{0,26},'{0,27},'{0,28},'{0,29},
'{1,4},'{1,5},'{1,6},'{1,7},'{1,8},'{1,9},'{1,10},'{1,11},'{1,12},'{1,13},'{1,14},'{1,15},'{1,16},'{1,17},'{1,18},'{1,19},'{1,20},'{1,21},'{1,22},'{1,23},'{1,24},'{1,25},'{1,26},'{1,27},'{1,28},'{1,29},'{1,30},
'{2,5},'{2,6},'{2,7},'{2,8},'{2,9},'{2,10},'{2,11},'{2,12},'{2,13},'{2,14},'{2,15},'{2,16},'{2,17},'{2,18},'{2,19},'{2,20},'{2,21},'{2,22},'{2,23},'{2,24},'{2,25},'{2,26},'{2,27},'{2,28},'{2,29},'{2,30},'{2,31},
'{3,6},'{3,7},'{3,8},'{3,9},'{3,10},'{3,11},'{3,12},'{3,13},'{3,14},'{3,15},'{3,16},'{3,17},'{3,18},'{3,19},'{3,20},'{3,21},'{3,22},'{3,23},'{3,24},'{3,25},'{3,26},'{3,27},'{3,28},'{3,29},'{3,30},'{3,31},
'{4,7},'{4,8},'{4,9},'{4,10},'{4,11},'{4,12},'{4,13},'{4,14},'{4,15},'{4,16},'{4,17},'{4,18},'{4,19},'{4,20},'{4,21},'{4,22},'{4,23},'{4,24},'{4,25},'{4,26},'{4,27},'{4,28},'{4,29},'{4,30},'{4,31},
'{5,8},'{5,9},'{5,10},'{5,11},'{5,12},'{5,13},'{5,14},'{5,15},'{5,16},'{5,17},'{5,18},'{5,19},'{5,20},'{5,21},'{5,22},'{5,23},'{5,24},'{5,25},'{5,26},'{5,27},'{5,28},'{5,29},'{5,30},'{5,31},
'{6,9},'{6,10},'{6,11},'{6,12},'{6,13},'{6,14},'{6,15},'{6,16},'{6,17},'{6,18},'{6,19},'{6,20},'{6,21},'{6,22},'{6,23},'{6,24},'{6,25},'{6,26},'{6,27},'{6,28},'{6,29},'{6,30},'{6,31},
'{7,10},'{7,11},'{7,12},'{7,13},'{7,14},'{7,15},'{7,16},'{7,17},'{7,18},'{7,19},'{7,20},'{7,21},'{7,22},'{7,23},'{7,24},'{7,25},'{7,26},'{7,27},'{7,28},'{7,29},'{7,30},'{7,31},
'{8,11},'{8,12},'{8,13},'{8,14},'{8,15},'{8,16},'{8,17},'{8,18},'{8,19},'{8,20},'{8,21},'{8,22},'{8,23},'{8,24},'{8,25},'{8,26},'{8,27},'{8,28},'{8,29},'{8,30},'{8,31},
'{9,12},'{9,13},'{9,14},'{9,15},'{9,16},'{9,17},'{9,18},'{9,19},'{9,20},'{9,21},'{9,22},'{9,23},'{9,24},'{9,25},'{9,26},'{9,27},'{9,28},'{9,29},'{9,30},'{9,31},
'{10,13},'{10,14},'{10,15},'{10,16},'{10,17},'{10,18},'{10,19},'{10,20},'{10,21},'{10,22},'{10,23},'{10,24},'{10,25},'{10,26},'{10,27},'{10,28},'{10,29},'{10,30},'{10,31},
'{11,14},'{11,15},'{11,16},'{11,17},'{11,18},'{11,19},'{11,20},'{11,21},'{11,22},'{11,23},'{11,24},'{11,25},'{11,26},'{11,27},'{11,28},'{11,29},'{11,30},'{11,31},
'{12,15},'{12,16},'{12,17},'{12,18},'{12,19},'{12,20},'{12,21},'{12,22},'{12,23},'{12,24},'{12,25},'{12,26},'{12,27},'{12,28},'{12,29},'{12,30},'{12,31},
'{13,16},'{13,17},'{13,18},'{13,19},'{13,20},'{13,21},'{13,22},'{13,23},'{13,24},'{13,25},'{13,26},'{13,27},'{13,28},'{13,29},'{13,30},'{13,31},
'{14,17},'{14,18},'{14,19},'{14,20},'{14,21},'{14,22},'{14,23},'{14,24},'{14,25},'{14,26},'{14,27},'{14,28},'{14,29},'{14,30},'{14,31},
'{15,18},'{15,19},'{15,20},'{15,21},'{15,22},'{15,23},'{15,24},'{15,25},'{15,26},'{15,27},'{15,28},'{15,29},'{15,30},'{15,31},
'{16,19},'{16,20},'{16,21},'{16,22},'{16,23},'{16,24},'{16,25},'{16,26},'{16,27},'{16,28},'{16,29},'{16,30},'{16,31},
'{17,20},'{17,21},'{17,22},'{17,23},'{17,24},'{17,25},'{17,26},'{17,27},'{17,28},'{17,29},'{17,30},'{17,31},
'{18,21},'{18,22},'{18,23},'{18,24},'{18,25},'{18,26},'{18,27},'{18,28},'{18,29},'{18,30},'{18,31},
'{19,22},'{19,23},'{19,24},'{19,25},'{19,26},'{19,27},'{19,28},'{19,29},'{19,30},'{19,31},
'{20,23},'{20,24},'{20,25},'{20,26},'{20,27},'{20,28},'{20,29},'{20,30},'{20,31},
'{21,24},'{21,25},'{21,26},'{21,27},'{21,28},'{21,29},'{21,30},'{21,31},
'{22,25},'{22,26},'{22,27},'{22,28},'{22,29},'{22,30},'{22,31},
'{23,26},'{23,27},'{23,28},'{23,29},'{23,30},'{23,31},
'{24,27},'{24,28},'{24,29},'{24,30},'{24,31},
'{25,28},'{25,29},'{25,30},'{25,31},
'{26,29},'{26,30},'{26,31},
'{27,30},'{27,31},
'{28,31}
};
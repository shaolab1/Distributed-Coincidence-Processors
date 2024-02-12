parameter int DELAY_PAIR = 432;
parameter int CHAN_DELAY_MAT[PAIR_NUM][2] = '{'{3,2},'{3,3},'{3,1},'{3,4},'{3,1},'{3,3},'{3,1},'{3,2},'{3,3},'{3,4},'{3,0},'{3,5},'{3,4},'{3,2},'{3,2},'{3,2},'{3,2},'{3,3},'{3,3},'{3,4},'{3,4},'{3,3},'{3,2},'{3,4},'{3,3},'{3,2},'{3,5},
                                            '{4,3},'{4,1},'{4,4},'{4,1},'{4,3},'{4,1},'{4,2},'{4,3},'{4,4},'{4,0},'{4,5},'{4,4},'{4,2},'{4,2},'{4,2},'{4,2},'{4,3},'{4,3},'{4,4},'{4,4},'{4,3},'{4,2},'{4,4},'{4,3},'{4,2},'{4,5},'{4,4},
                                            '{3,1},'{3,4},'{3,1},'{3,3},'{3,1},'{3,2},'{3,3},'{3,4},'{3,0},'{3,5},'{3,4},'{3,2},'{3,2},'{3,2},'{3,2},'{3,3},'{3,3},'{3,4},'{3,4},'{3,3},'{3,2},'{3,4},'{3,3},'{3,2},'{3,5},'{3,4},'{3,3},
                                            '{2,4},'{2,1},'{2,3},'{2,1},'{2,2},'{2,3},'{2,4},'{2,0},'{2,5},'{2,4},'{2,2},'{2,2},'{2,2},'{2,2},'{2,3},'{2,3},'{2,4},'{2,4},'{2,3},'{2,2},'{2,4},'{2,3},'{2,2},'{2,5},'{2,4},'{2,3},
                                            '{3,1},'{3,3},'{3,1},'{3,2},'{3,3},'{3,4},'{3,0},'{3,5},'{3,4},'{3,2},'{3,2},'{3,2},'{3,2},'{3,3},'{3,3},'{3,4},'{3,4},'{3,3},'{3,2},'{3,4},'{3,3},'{3,2},'{3,5},'{3,4},'{3,3},
                                            '{1,3},'{1,1},'{1,2},'{1,3},'{1,4},'{1,0},'{1,5},'{1,4},'{1,2},'{1,2},'{1,2},'{1,2},'{1,3},'{1,3},'{1,4},'{1,4},'{1,3},'{1,2},'{1,4},'{1,3},'{1,2},'{1,5},'{1,4},'{1,3},
                                            '{4,1},'{4,2},'{4,3},'{4,4},'{4,0},'{4,5},'{4,4},'{4,2},'{4,2},'{4,2},'{4,2},'{4,3},'{4,3},'{4,4},'{4,4},'{4,3},'{4,2},'{4,4},'{4,3},'{4,2},'{4,5},'{4,4},'{4,3},
                                            '{1,2},'{1,3},'{1,4},'{1,0},'{1,5},'{1,4},'{1,2},'{1,2},'{1,2},'{1,2},'{1,3},'{1,3},'{1,4},'{1,4},'{1,3},'{1,2},'{1,4},'{1,3},'{1,2},'{1,5},'{1,4},'{1,3},
                                            '{3,3},'{3,4},'{3,0},'{3,5},'{3,4},'{3,2},'{3,2},'{3,2},'{3,2},'{3,3},'{3,3},'{3,4},'{3,4},'{3,3},'{3,2},'{3,4},'{3,3},'{3,2},'{3,5},'{3,4},'{3,3},
                                            '{1,4},'{1,0},'{1,5},'{1,4},'{1,2},'{1,2},'{1,2},'{1,2},'{1,3},'{1,3},'{1,4},'{1,4},'{1,3},'{1,2},'{1,4},'{1,3},'{1,2},'{1,5},'{1,4},'{1,3},
                                            '{2,0},'{2,5},'{2,4},'{2,2},'{2,2},'{2,2},'{2,2},'{2,3},'{2,3},'{2,4},'{2,4},'{2,3},'{2,2},'{2,4},'{2,3},'{2,2},'{2,5},'{2,4},'{2,3},
                                            '{3,5},'{3,4},'{3,2},'{3,2},'{3,2},'{3,2},'{3,3},'{3,3},'{3,4},'{3,4},'{3,3},'{3,2},'{3,4},'{3,3},'{3,2},'{3,5},'{3,4},'{3,3},
                                            '{4,4},'{4,2},'{4,2},'{4,2},'{4,2},'{4,3},'{4,3},'{4,4},'{4,4},'{4,3},'{4,2},'{4,4},'{4,3},'{4,2},'{4,5},'{4,4},'{4,3},
                                            '{0,2},'{0,2},'{0,2},'{0,2},'{0,3},'{0,3},'{0,4},'{0,4},'{0,3},'{0,2},'{0,4},'{0,3},'{0,2},'{0,5},'{0,4},'{0,3},
                                            '{5,2},'{5,2},'{5,2},'{5,3},'{5,3},'{5,4},'{5,4},'{5,3},'{5,2},'{5,4},'{5,3},'{5,2},'{5,5},'{5,4},'{5,3},
                                            '{4,2},'{4,2},'{4,3},'{4,3},'{4,4},'{4,4},'{4,3},'{4,2},'{4,4},'{4,3},'{4,2},'{4,5},'{4,4},'{4,3},
                                            '{2,2},'{2,3},'{2,3},'{2,4},'{2,4},'{2,3},'{2,2},'{2,4},'{2,3},'{2,2},'{2,5},'{2,4},'{2,3},
                                            '{2,3},'{2,3},'{2,4},'{2,4},'{2,3},'{2,2},'{2,4},'{2,3},'{2,2},'{2,5},'{2,4},'{2,3},
                                            '{2,3},'{2,4},'{2,4},'{2,3},'{2,2},'{2,4},'{2,3},'{2,2},'{2,5},'{2,4},'{2,3},
                                            '{2,4},'{2,4},'{2,3},'{2,2},'{2,4},'{2,3},'{2,2},'{2,5},'{2,4},'{2,3},
                                            '{3,4},'{3,3},'{3,2},'{3,4},'{3,3},'{3,2},'{3,5},'{3,4},'{3,3},
                                            '{3,3},'{3,2},'{3,4},'{3,3},'{3,2},'{3,5},'{3,4},'{3,3},
                                            '{4,2},'{4,4},'{4,3},'{4,2},'{4,5},'{4,4},'{4,3},
                                            '{4,4},'{4,3},'{4,2},'{4,5},'{4,4},'{4,3},
                                            '{3,3},'{3,2},'{3,5},'{3,4},'{3,3},
                                            '{2,2},'{2,5},'{2,4},'{2,3},
                                            '{4,5},'{4,4},'{4,3},
                                            '{3,4},'{3,3},
                                            '{2,3}};
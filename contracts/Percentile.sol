// // SPDX-License-Identifier: MIT

// pragma solidity 0.8.17;

// import "./Library.sol";

// contract Percentile {
//     uint public totalpaidInvoices;
//     uint public totalpaidInvoices2;
//     uint public totalInvoices;
//     uint public totalInvoices2;
//     uint public sum_of_diff_squared_invoices;
//     uint public sum_of_diff_squared_invoices2;
//     int256 public zscore;
//     int256 public zscore2;
//     uint public mean;
//     uint public mean2;
//     uint public std;
//     uint public std2;
//     // zscore => percentile
//     mapping (int => uint) public table;
//     // percentile => zscore
//     mapping (uint => int) public zTable;

//     constructor() {   
//         table[-241] = 1;
//         table[-205] = 2;
//         table[-188] = 3;
//         table[-175] = 4;
//         table[-165] = 5;
//         table[-156] = 6;
//         table[-148] = 7;
//         table[-141] = 8;
//         table[-134] = 9;
//         table[-128] = 10;
//         table[-123] = 11;
//         table[-118] = 12;
//         table[-113] = 13;
//         table[-108] = 14;
//         table[-104] = 15;
//         table[-100] = 16;
//         table[-95] = 17;
//         table[-92] = 18;
//         table[-88] = 19;
//         table[-84] = 20;
//         table[-81] = 21;
//         table[-77] = 22;
//         table[-74] = 23;
//         table[-71] = 24;
//         table[-67] = 25;
//         table[-64] = 26;
//         table[-61] = 27;
//         table[-58] = 28;
//         table[-55] = 29;
//         table[-52] = 30;
//         table[-50] = 31;
//         table[-47] = 32;
//         table[-44] = 33;
//         table[-41] = 34;
//         table[-39] = 35;
//         table[-36] = 36;
//         table[-33] = 37;
//         table[-31] = 38;
//         table[-28] = 39;
//         table[-25] = 40;
//         table[-23] = 41;
//         table[-20] = 42;
//         table[-18] = 43;
//         table[-15] = 44;
//         table[-13] = 45;
//         table[-10] = 46;
//         table[-8] = 47;
//         table[-5] = 48;
//         table[-3] = 49;
//         table[0] = 50;
//         table[3] = 51;
//         table[5] = 52;
//         table[8] = 53;
//         table[10] = 54;
//         table[13] = 55;
//         table[15] = 56;
//         table[18] = 57;
//         table[20] = 58;
//         table[23] = 59;
//         table[25] = 60;
//         table[28] = 61;
//         table[31] = 62;
//         table[33] = 63;
//         table[36] = 64;
//         table[39] = 65;
//         table[41] = 66;
//         table[44] = 67;
//         table[47] = 68;
//         table[50] = 69;
//         table[52] = 70;
//         table[55] = 71;
//         table[58] = 72;
//         table[61] = 73;
//         table[64] = 74;
//         table[67] = 75;
//         table[71] = 76;
//         table[74] = 77;
//         table[77] = 78;
//         table[81] = 79;
//         table[84] = 80;
//         table[88] = 81;
//         table[92] = 82;
//         table[95] = 83;
//         table[100] = 84;
//         table[104] = 85;
//         table[108] = 86;
//         table[113] = 87;
//         table[118] = 88;
//         table[123] = 89;
//         table[128] = 90;
//         table[134] = 91;
//         table[141] = 92;
//         table[148] = 93;
//         table[156] = 94;
//         table[165] = 95;
//         table[175] = 96;
//         table[188] = 97;
//         table[205] = 98;
//         table[241] = 99;

//         zTable[1] = -241;
//         zTable[2] = -205;
//         zTable[3] = -188;
//         zTable[4] = -175;
//         zTable[5] = -165;
//         zTable[6] = -156;
//         zTable[7] = -148;
//         zTable[8] = -141;
//         zTable[9] = -134;
//         zTable[10] = -128;
//         zTable[11] = -123;
//         zTable[12] = -118;
//         zTable[13] = -113;
//         zTable[14] = -108;
//         zTable[15] = -104;
//         zTable[16] = -100;
//         zTable[17] = -95;
//         zTable[18] = -92;
//         zTable[19] = -88;
//         zTable[20] = -84;
//         zTable[21] = -81;
//         zTable[22] = -77;
//         zTable[23] = -74;
//         zTable[24] = -71;
//         zTable[25] = -67;
//         zTable[26] = -64;
//         zTable[27] = -61;
//         zTable[28] = -58;
//         zTable[29] = -55;
//         zTable[30] = -52;
//         zTable[31] = -50;
//         zTable[32] = -47;
//         zTable[33] = -44;
//         zTable[34] = -41;
//         zTable[35] = -39;
//         zTable[36] = -36;
//         zTable[37] = -33;
//         zTable[38] = -31;
//         zTable[39] = -28;
//         zTable[40] = -25;
//         zTable[41] = -23;
//         zTable[42] = -20;
//         zTable[43] = -18;
//         zTable[44] = -15;
//         zTable[45] = -13;
//         zTable[46] = -10;
//         zTable[47] = -8;
//         zTable[48] = -5;
//         zTable[49] = -3;
//         zTable[50] = 0;
//         zTable[51] = 3;
//         zTable[52] = 5;
//         zTable[53] = 8;
//         zTable[54] = 10;
//         zTable[55] = 13;
//         zTable[56] = 15;
//         zTable[57] = 18;
//         zTable[58] = 20;
//         zTable[59] = 23;
//         zTable[60] = 25;
//         zTable[61] = 28;
//         zTable[62] = 31;
//         zTable[63] = 33;
//         zTable[64] = 36;
//         zTable[65] = 39;
//         zTable[66] = 41;
//         zTable[67] = 44;
//         zTable[68] = 47;
//         zTable[69] = 50;
//         zTable[70] = 52;
//         zTable[71] = 55;
//         zTable[72] = 58;
//         zTable[73] = 61;
//         zTable[74] = 64;
//         zTable[75] = 67;
//         zTable[76] = 71;
//         zTable[77] = 74;
//         zTable[78] = 77;
//         zTable[79] = 81;
//         zTable[80] = 84;
//         zTable[81] = 88;
//         zTable[82] = 92;
//         zTable[83] = 95;
//         zTable[84] = 100;
//         zTable[85] = 104;
//         zTable[86] = 108;
//         zTable[87] = 113;
//         zTable[88] = 118;
//         zTable[89] = 123;
//         zTable[90] = 128;
//         zTable[91] = 134;
//         zTable[92] = 141;
//         zTable[93] = 148;
//         zTable[94] = 156;
//         zTable[95] = 165;
//         zTable[96] = 175;
//         zTable[97] = 188;
//         zTable[98] = 205;
//         zTable[99] = 241;
//     }



//     function computePercentile(uint256 _paid) public returns(int256) {
//         totalpaidInvoices += _paid;
//         totalInvoices += 1;
//         mean = totalpaidInvoices / totalInvoices;
//         int256 paid_mean;
//         int sign = 1;
//         if (_paid > mean) {
//             paid_mean = int256(_paid - mean);
//         } else {
//             sign = -1;
//             paid_mean = int256(mean - _paid);
//         }
//         sum_of_diff_squared_invoices += uint(paid_mean)**2;
//         std = Math.sqrt(sum_of_diff_squared_invoices / (totalInvoices>1?totalInvoices-1:1));
//         std = std>0?std:1;
//         zscore = sign * paid_mean * 100 / int256(std);
//         return zscore;
//     }

//     function computePercentile2(uint256 _paid) public returns(int256) {
//         totalpaidInvoices2 += _paid;
//         totalInvoices2 += 1;
//         mean2 = totalpaidInvoices2 / totalInvoices2;
//         int256 paid_mean;
//         int sign = 1;
//         if (_paid > mean2) {
//             paid_mean = int256(_paid - mean2);
//         } else {
//             sign = -1;
//             paid_mean = int256(mean2 - _paid);
//         }
//         sum_of_diff_squared_invoices2 += uint(paid_mean)**2;
//         std2 = Math.sqrt(sum_of_diff_squared_invoices2 / (totalInvoices2>1?totalInvoices2-1:1));
//         std2 = std2>0?std2:1;
//         zscore2 = sign * paid_mean * 100 / int256(std2);
//         return zscore2;
//     }

//     function computePercentileFromData(
//         bool skip,
//         uint _paid,
//         uint _totalpaidInvoices,
//         uint _totalInvoices,
//         uint _sum_of_diff_squared_invoices
//     ) public view returns(uint, uint) {
//         uint _mean = _totalpaidInvoices / _totalInvoices;
//         int256 paid_mean;
//         int sign = 1;
//         if (_paid > _mean) {
//             paid_mean = int256(_paid - _mean);
//         } else {
//             sign = -1;
//             paid_mean = int256(_mean - _paid);
//         }
//         if (!skip) {
//             _sum_of_diff_squared_invoices += uint(paid_mean)**2;
//         }
//         uint _std = Math.sqrt(_sum_of_diff_squared_invoices / (_totalInvoices>1?_totalInvoices-1:1));
//         _std = _std>0?_std:1;
//         return (
//             getPercentile(sign * paid_mean * 100 / int256(_std)),
//             _sum_of_diff_squared_invoices
//         );
//     }

//     function getPercentile(int _zscore) public view returns(uint){
//         if (_zscore >= 241) {
//             return 99;
//         }
//         if (table[_zscore] != 0) {
//             return table[_zscore];
//         }
//         while(table[_zscore] == 0) {
//             _zscore += 1;
//         } 
//         return table[_zscore];
//     }

//     function getPaid4Percentile(uint _percentile) public view returns(uint) {
//         require(_percentile != 0 && _percentile < 100, "Invalid percentiles");
//         int _currZscore = zTable[_percentile];
//         return uint(_currZscore) * std + mean;
//     }

//     function getPaid4Percentile2(uint _percentile) public view returns(uint) {
//         require(_percentile != 0 && _percentile < 100, "Invalid percentiles");
//         int _currZscore = zTable[_percentile];
//         return uint(_currZscore) * std2 + mean2;
//     }

//     function getQ4() public virtual view returns(int256) {
//         int256 q4Zscore = 67;
//         return q4Zscore * int256(std + mean);
//     }

//     function get2Q4() public virtual view returns(int256) {
//         int256 q4Zscore = 67;
//         return q4Zscore * int256(std2 + mean2);
//     }

//     function getQ3() public virtual view returns(int256) {
//         int256 q3Zscore = 0;
//         return q3Zscore * int256(std + mean);
//     }

//     function get2Q3() public virtual view returns(int256) {
//         int256 q3Zscore = 0;
//         return q3Zscore * int256(std2 + mean2);
//     }

//     function getQ2() public virtual view returns(int256) {
//         int256 q2Zscore = -67;
//         return q2Zscore * int256(std + mean);
//     }

//     function get2Q2() public virtual view returns(int256) {
//         int256 q2Zscore = -67;
//         return q2Zscore * int256(std2 + mean2);
//     }

//     function getQ1() public virtual view returns(int256) {
//         int256 q1Zscore = -241;

//         return q1Zscore * int256(std + mean);
//     }

//     function get2Q1() public virtual view returns(int256) {
//         int256 q1Zscore = -241;

//         return q1Zscore * int256(std2 + mean2);
//     }

//     function getRandomPercentile(uint _randomNumber) public virtual returns(uint) {
//         uint result;
//         if (_randomNumber <= 2100) {
//             result = 0;
//         } else if (_randomNumber <= 5100) {
//             result = 10;
//         } else if (_randomNumber <= 10000) {
//             result = 20;
//         } else if (_randomNumber <= 90000) {
//             result = 30;
//         } else if (_randomNumber <= 190000) {
//             result = 40;
//         } else if (_randomNumber <= 310000) {
//             result = 50;
//         } else if (_randomNumber <= 450000) {
//             result = 60;
//         } else if (_randomNumber <= 610000) {
//             result = 70;
//         } else if (_randomNumber <= 790000) {
//             result = 80;
//         } else if (_randomNumber <= 1000000) {
//             result = 90;
//         }
//         return result + (_randomNumber % 9);
//     }
// }
function P = paper_values()
% PAPER_VALUES  The result tables as printed in the paper (typed from the two PDF files).
%
%   P.T4v2, P.T5v2 : version 2.0 (April 9, 2023), Table 4 (forward) and Table 5 (inverse)
%   P.T4v1, P.T5v1 : version 1 (January 26, 2022), Table 4 and Table 5
% Fields: trN and trR = training NRMSE and R2, teN and teR = test NRMSE and R2 (one value per
% joint), avg = the "All Joints" row [trN trR teN teR], dec = decimals printed in that row.

P.T4v2.trN = [0.635 0.717 0.726 0.866 0.865 0.838]; P.T4v2.trR = [59.733 48.603 47.323 25.083 25.099 29.852];
P.T4v2.teN = [0.638 0.829 0.876 0.894 0.869 0.845]; P.T4v2.teR = [59.236 31.293 23.179 20.098 24.534 28.513];
P.T4v2.avg = [0.7745 39.2822 0.82517 31.1422];      P.T4v2.dec = [4 4 5 4];

P.T5v2.trN = [0.418 0.595 0.555 0.673 0.679 0.551]; P.T5v2.trR = [82.502 64.615 69.228 54.72 53.902 69.635];
P.T5v2.teN = [0.447 0.681 0.549 0.705 0.71 0.559];  P.T5v2.teR = [79.982 53.607 69.841 50.253 49.615 68.723];
P.T5v2.avg = [0.5785 65.767 0.6085 62.0035];        P.T5v2.dec = [4 3 4 4];

P.T4v1.trN = [0.681 0.844 0.749 0.859 0.853 0.829]; P.T4v1.trR = [55.359 28.744 43.898 26.496 27.252 31.567];
P.T4v1.teN = [0.841 1.169 1.965 0.89 0.887 0.952];  P.T4v1.teR = [44.045 9.54 6.532 23.964 25.936 23.87];
P.T4v1.avg = [0.8025 35.5527 1.1173 22.3145];       P.T4v1.dec = [4 4 4 4];

P.T5v1.trN = [0.419 1.582 1.893 0.673 1.012 0.552]; P.T5v1.trR = [82.453 -48.673 -75.514 54.677 13.096 69.582];
P.T5v1.teN = [0.447 1.546 1.964 0.709 1.077 0.559]; P.T5v1.teR = [80.001 -35.737 -62.339 49.696 9.613 68.691];
P.T5v1.avg = [1.0218 15.9368 1.0503 18.3208];       P.T5v1.dec = [4 4 4 4];
end

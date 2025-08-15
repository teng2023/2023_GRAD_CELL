# 2023_GRAD_CELL (2023 IC競賽初賽)

## 檔案介紹

Data (pattern) 來自 **img1.pattern**,  **img2.pattern**, **img3.pattern**, **img4.pattern**, **img5.pattern**, **img6.pattern** 

**LASER** 是原始檔案

**tb.sv**, **tb_test.sv** 是TB  

### Pass the test bench simulation

**LASER_v2.v** 使用直接計算40個點與圓心的距離。

### Failed the test bench simulation

**LASER_v1.v** 使用類似於convolution的方式。

(Failure reason：演算法有問題)



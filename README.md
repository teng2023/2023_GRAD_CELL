# 2023_GRAD_CELL (2023 IC競賽 研究所 初賽)

## 題目說明

![question](https://github.com/teng2023/2023_GRAD_CELL/blob/main/question.png)

## 檔案介紹

Pattern：**img1.pattern**,  **img2.pattern**, **img3.pattern**, **img4.pattern**, **img5.pattern**, **img6.pattern** 

Original file：**LASER.v** 

Test Bench：**tb.sv**, **tb_test.sv** 

### *Pass the test bench simulation*

**LASER_v2.v**：使用直接計算40個點與圓心的距離。

### *Failed the test bench simulation*

**LASER_v1.v**：使用類似於convolution的方式。

(Failure reason：演算法有問題)



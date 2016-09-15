# 全国主要城市天气可视化
REmap是ECharts中交互地图可视化功能的R接口，通过它可以直接使用R代码（而不必写JS代码）来实现交互地图可视化。本文将介绍如何使用REmap包实现全国主要城市天气可视化。
## 1 准备工作
### 1.1 安装R和RStudio
见R基础部分
### 1.2 安装REmap
``` r
library(devtools)
install_github('lchiffon/REmap')
```
请注意，以上命令默认你已经安装了devtools，如果你没有安装devtools，那么请先安装之。
### 1.3 准备三张天气图片
图片可以自行百度或者设计，或者直接引用我github上的图片。
图片链接地址https://github.com/wcc3358/ChinaWeatherVisualization
图片形式大致如下：
 
将天气数据做简化，简化后只有晴天、多云以及阴天三种。
## 2 载入REmap包
``` r
library(rvest) #用来爬取数据
library(REmap) #实现地图可视化
options(remap.js.web=T)
```
设置options(remap.js.web=T)后，生成html将保存在当前工作目录，否则它会保存在默认的临时文件夹中。
## 3 爬取天气数据
选择中央气象台的天气数据，采用rvest包爬取天气数据：
 
 
``` r
## 爬取天气数据
website <- "http://www.nmc.cn/publish/forecast/china.html"
web <- read_html(website,encoding = "UTF-8") 
weather.data <- web %>% html_nodes("div.area ul li") %>% html_text()
fun <- function(x){
  temp  <- strsplit(x,split = "[\n]+")[[1]]  
  item <- gsub(pattern = "\\s+",replacement = "",x = temp)  
  res <- item[item!=""]
  res
}
weather.data <- sapply(weather.data,fun)
# 转置
weather.data <- t(weather.data)
# 重命名行和列
weather.data <- as.data.frame(weather.data,row.names=1:nrow(dat0),stringsAsFactors=FALSE)
colnames(weather.data) <- c("area","weather","temperature")
```
## 4 数据整理
继续整理数据，生成衍生变量：weatherc
``` r
# 数据整理
# 获取末尾的40个城市的记录
weather.data <- tail(weather.data,40)
# 提取天气中的前3个字儿
weather <- substr(weather.data$weather,1,3)
weather
#  [1] "多云"   "多云转" "多云"   "阵雨转" "阴转小" "晴转多"
#  [7] "晴"     "晴"     "晴"     "晴"     "晴转多" "多云"  
# [13] "晴转小" "阵雨转" "大雨"   "大雨转" "大雨转" "大雨"  
# [19] "大到暴" "小雨转" "晴"     "多云"   "阵雨"   "阴"    
# [25] "晴"     "多云"   "晴"     "多云"   "多云"   "小雨转"
# [31] "多云"   "阴转多" "中雨"   "小雨转" "阵雨转" "晴"    
# [37] "多云转" "晴转多" "晴"     "阴转小"

# 查出匹配字段的索引
ind1 <- grep("晴",weather)
ind20 <- grep("云",weather)
ind21 <- grep("阴",weather)
ind2 <- c(ind20,ind21)
ind3 <- grep("雨",weather)
# 将各匹配字段赋对应的英文天气
weather.data$weatherc <- NA
weather.data$weatherc[ind1] <- "sunny"
weather.data$weatherc[ind2] <- "cloudy"
weather.data$weatherc[ind3] <- "rainy"
# 去掉了未能成功赋值的行
weather.data <- weather.data[-19,]
```
整理后的数据如上，最后一列weatherc表示简化后的天气类型，即是sunny、cloudy还是rainy，其中小雨转多云、多云转晴这些天气状况直接就简化为rainy以及cloudy，简化后方便与准备工作3中所表示的三种天气图片相对应。
具体的代码不做详细分析，中间涉及到正则匹配和替换，如果你不了解正则，去百度搜搜三十分钟学会正则表达式，你就能大致明白。
我想特别说明的是，作者的这个包里提取经纬度的函数get_city_coord在提取三个字的城市时存在BUG，所以上述代码在最后使用代码dat0[-c(1,6),]时暂时去掉了三个字的城市数据。该部分BUG已经提交给作者，相信很快就会修复。
5 可视化展示
可视化展示的三个步骤：
a.	采用get_city_coord获取城市的经纬度数据
b.	封装城市的图片以及标签信息
c.	采用remapB获做城市天气可视化展示
``` r
remapB(center = c(104.114129,37.550339),
       zoom = 5,
       color = "Bright",
       title = "",
       subtitle = "",
       markLineData = NA,
       markPointData = NA,
       markLineTheme = markLineControl(),
       markPointTheme = markPointControl(),
       geoData = NA)
```
remapB函数相关参数说明：
- 	makePointData：城市相关信息，包括需要展示的天气状况图片以及文字信息
- 	geoData：城市对应的经纬度
- 	color：地图的主题颜色，有"Bright", "Blue", "light", "dark", "redalert", "googlelite", "grassgreen", "midnight", "pink", "darkgreen", "bluish", "grayscale", "hardedge"可选，示例见下文
- 	subtitle：副标题
- 	makePointTheme：控制显示的图片的大小，显示效果等等
- 	markLineData：标记线的数据
- 	markLineTheme：标记线的主题
- 	zoom: Bmap的大小缩放zoom:5国家数据 zoom:15 城市的数据
 
``` r 
# 天气可视化展示
# remap.init()
geoData <- sapply(weather.data$area, get_city_coord)
geoData
# 香港      澳门      台北      北京      西青
# [1,] 114.17199 113.54940 121.52487 116.41355 117.01380
# [2,]  22.28109  22.19296  25.04218  39.91101  39.14744
# 天津      太原      沈阳      长春      上海
# [1,] 117.20591 112.55706 123.43897 125.33017 121.48024
# [2,]  39.09091  37.87689  41.81134  43.82178  31.23631
# 南京      杭州      合肥      南昌      济南
# [1,] 118.80289 120.16169 117.23545 115.86453 117.00132
# [2,]  32.06473  30.28006  31.82687  28.68767  36.67163
# 郑州      武汉      长沙      广州      深圳
# [1,] 113.63135 114.31183 112.94533 113.27079 114.06611
# [2,]  34.75349  30.59843  28.23397  23.13531  22.54851
# 中沙      海口     重庆      成都      贵阳      昆明
# [1,] 114.39999 110.20642 106.5572 104.07122 106.63682 102.83967
# [2,]  15.91595  20.05006  29.5710  30.57628  26.65275  24.88595
# 拉萨      西安      兰州      西宁      银川      台北
# [1,] 91.12103 108.94631 103.84069 101.78427 106.23898 121.52487
# [2,] 29.65009  34.34744  36.06731  36.62348  38.49239  25.04218
citynames <- dimnames(geoData)[[2]]
geoData <- as.data.frame(t(geoData),row.names = 1:nrow(geoData),stringsAsFactors = FALSE)
colnames(geoData) <- c("lon","lat")
geoData$city <- citynames
symbol <- paste0("image://https://github.com/wcc3358/ChinaWeatherVisualization/",weather.data$weatherc,".png")
tooltip <- paste(a=weather.data$area,"----------",weather.data$weather,weather.data$temperature,sep="<br>")
newdata <- data.frame(a=weather.data$area,symbol=symbol,tooltip=tooltip,stringsAsFactors=FALSE)
remapB(markPointData = newdata,
       geoData = geoData,
       color="Blue",
       title = "中国城市主要天气",
       markPointTheme = markPointControl(symbolSize=20,
                                         effectType='bounce',
                                         effect=T,
                                         color = "Random"))
```
展示结果如下图，这里只是截了一个屏，而其实这张图是动态的，天气图标会有一个浮动的效果，并且鼠标移动到天气图标上，会有一个文字效果展示具体的天气和温度数据。
 

## 5 小结
本文实现了全国主要城市天气可视化，这仅是REmap包的一个应用，它还可以用来做著名的百度迁徙图以及城市热力图等等。
REmap包的官方文档详见：https://github.com/Lchiffon/REmap



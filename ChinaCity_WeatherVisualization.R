## 中国主要城市天气可视化

## 载入需要的packages
library(rvest) #用来爬取数据
library(REmap) #实现地图可视化
options(remap.js.web=T) 
#设置options(remap.js.web=T)后，生成html将保存在当前工作目录，否则它会保存在默认的临时文件夹中。

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
weather.data <- weather.data[-c(1,2,9,11,14,19,27,39),]
# 去掉三个字儿的城市（因为后面get_city_coord获取经纬度会报错）

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

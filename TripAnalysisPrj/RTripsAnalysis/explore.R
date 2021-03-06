library(ggplot2) 
library(data.table)
library(corrplot)
library(DMwR)

min_max_norm <- function(x) { return((x-min(x))/(max(x)-min(x)))}

car_trips <- read.csv("./csv/output/all_aggregated_trips.csv")
car_trips$X <- NULL

# Imbalance of fuel param
table(car_trips$car_fuel)
car_trips <- car_trips[(car_trips$car_fuel == levels(car_trips$car_fuel)[2]),]
car_trips$car_fuel <- NULL

# Remove 0 distance outliers
car_trips <- car_trips[0 < car_trips$distance,]
car_trips$co2_emission_per_dist <- car_trips$co2_emission / car_trips$time_diff 
car_trips$co2_emission <- NULL

summary(car_trips)

str(car_trips)
summary(car_trips)

boxplot(car_trips$co2_emission_per_dist, main = "CO2 emission per distance", ylab = "kg/km")
hist(car_trips$co2_emission_per_dist, breaks=100, main = "CO2 emission per distance")

#univariate outliers detection (makes the model worse)
#max_co2_border <- sd(car_trips$co2_emission_per_dist) * 3 + mean(car_trips$co2_emission_per_dist)
#car_trips <- car_trips[car_trips$co2_emission_per_dist<=max_co2_border,]

#boxplot(car_trips$co2_emission_per_dist, main = "CO2 emission per distance", ylab = "kg/km")
#hist(car_trips$co2_emission_per_dist, breaks=100)

boxplot(car_trips$time_diff, main = "Trip duration", ylab = "Hours")
hist(car_trips$time_diff, breaks=100, main = "Trip duration")

boxplot(car_trips$speed_avg, main = "Speed average", ylab = "Km/h")
hist(car_trips$speed_avg, breaks=100, main = "Speed average")


car_trips_znorm <- as.data.frame(lapply(car_trips, function(x){return(if (is.numeric(x)) scale(x) else x) })) 
car_trips_minmax <- as.data.frame(lapply(car_trips, function(x){return(if (is.numeric(x)) min_max_norm(x) else x) }))
summary(car_trips_minmax)

numeric_car_trips <- car_trips[sapply(car_trips_znorm, is.numeric)]
numeric_cor_matrix <- cor(numeric_car_trips)
corrplot(numeric_cor_matrix, method="number")


#LOF outliers detection
outlier.scores <- lofactor(numeric_car_trips, k=5)
plot(density(outlier.scores))
outliers <- order(outlier.scores, decreasing=T)[1:sum(1.5<outlier.scores)]
car_trips$outliers <- FALSE
car_trips$outliers[outliers] <- TRUE

#pairs(~co2_emission_per_dist + highway_val + car_construction_year + car_engine_displ +
#        throttle_position_avg + throttle_position_diff_avg +
#        speed_avg + rpm_avg + rpm_diff_avg + acceleration_avg + deceleration_avg +
#        intake_temp_avg + engine_load_avg,
#        data=car_trips_znorm, main="Simple Scatterplot Matrix")


qplot(highway, co2_emission_per_dist, data = car_trips, geom="jitter") +
  ggtitle("Dependency between CO2 emissions and highway type") + 
  xlab("CO2 emission per km") +
  ylab("Highway type")

qplot(car_manufacturer, co2_emission_per_dist, data = car_trips, geom="jitter") +
  ggtitle("CO2 emission based on vehicle manufacturer") + xlab("CO2 emission per km") +
  ylab("Vehicle manufacturer") 

ggplot(data=car_trips, aes(y=co2_emission_per_dist)) + 
   geom_point(aes(x=speed_avg, colour=outliers, shape=outliers)) + 
  ggtitle("Outliers") + xlab("CO2 emission per km") +
  ylab("Vehicle speed") + theme(legend.position="bottom",legend.direction="horizontal")

ggplot(data=car_trips, aes(y=co2_emission_per_dist)) + 
  geom_point(aes(x=rpm_avg, colour=outliers, shape=outliers)) + ggtitle("Outliers") + xlab("CO2 emission per km") +
  ylab("RPM") + theme(legend.position="bottom",legend.direction="horizontal")

ggplot(data=car_trips, aes(y=co2_emission_per_dist)) + 
  geom_point(aes(x=acceleration_avg, colour=outliers, shape=outliers)) + 
  ggtitle("Emission and Intake temp")

ggplot(data=car_trips, aes(y=co2_emission_per_dist)) + 
  geom_point(aes(x=acceleration_avg, colour=car_manufacturer)) + ggtitle("Dependency between Emission and Acceleration") + 
  xlab("CO2 emission per km") +
  ylab("Acceleration") + theme(legend.position="bottom",legend.direction="horizontal")



car_trips <- car_trips[!car_trips$outliers,]
car_trips_znorm <- as.data.frame(lapply(car_trips, function(x){return(if (is.numeric(x)) scale(x) else x) })) 
car_trips_minmax <- as.data.frame(lapply(car_trips, function(x){return(if (is.numeric(x)) min_max_norm(x) else x) }))

write.csv(file="./csv/output/car_trips_minmax.csv", x=car_trips_minmax)
write.csv(file="./csv/output/car_trips_znorm.csv", x=car_trips_znorm)
DROP DATABASE IF EXISTS kl_park_easy;
CREATE DATABASE kl_park_easy;
USE kl_park_easy;

CREATE TABLE loyalty_tiers(
    loyalty_tier_id VARCHAR(20) NOT NULL,
    tier_name VARCHAR(50) NOT NULL,
    discount_percentage INT NOT NULL,
    min_parkpoints_earned_required INT NOT NULL,
    PRIMARY KEY(loyalty_tier_id)
);

CREATE TABLE sensors(
    sensor_id VARCHAR(20) NOT NULL,
    sensor_status ENUM('operational', 'need_calibration', 'offline') NOT NULL,
    manufacture_date DATE NOT NULL,
    PRIMARY KEY(sensor_id)
);

CREATE TABLE location_zones(
    location_zone_id VARCHAR(20) NOT NULL,
    location_zone_name VARCHAR(100) NOT NULL,
    air_quality_index DECIMAL(5,2) NULL DEFAULT NULL,
    pm25_value DECIMAL(5,2) NULL DEFAULT NULL,
    pm10_value DECIMAL(5,2) NULL DEFAULT NULL,
    co_value DECIMAL(5,2) NULL DEFAULT NULL,
    co2_value DECIMAL(5,2) NULL DEFAULT NULL,
    no2_value DECIMAL(5,2) NULL DEFAULT NULL,
    o3_value DECIMAL(5,2) NULL DEFAULT NULL,
    so2_value DECIMAL(5,2) NULL DEFAULT NULL,
    PRIMARY KEY(location_zone_id)
);

CREATE TABLE parking_spots(
    parking_spot_id VARCHAR(20) NOT NULL,
    sensor_id VARCHAR(20) NOT NULL,
    location_zone_id VARCHAR(20) NOT NULL,
    space_type ENUM('standard', 'premium_covered', 'ev_charger', 'motorbike', 'reserved') NOT NULL,
    reserved_license_plate_number VARCHAR(30) NULL DEFAULT NULL,
    standard_hourly_rate DECIMAL(7,2) NOT NULL,
    site_tier ENUM('tier_1','tier_2','tier_3') NOT NULL,
    real_time_demand_rating ENUM('low','moderate','high') NOT NULL,
    predicted_current_demand_rating ENUM('low','moderate','high') NULL DEFAULT NULL,
    PRIMARY KEY(parking_spot_id),
    UNIQUE(sensor_id),
    FOREIGN KEY(sensor_id) REFERENCES sensors(sensor_id),
    FOREIGN KEY(location_zone_id) REFERENCES location_zones(location_zone_id)
);

CREATE TABLE clients(
    client_id VARCHAR(20) NOT NULL,
    full_name VARCHAR(100) NOT NULL,    
    referral_source ENUM('google_ad', 'social_media') NULL DEFAULT NULL,
    loyalty_tier_id VARCHAR(20) NOT NULL,
    parkpoints_balance INT NOT NULL,
    parkpoints_elite_balance INT NOT NULL,
    business_relationship_type ENUM('individual_commuter', 'corporate_fleet_account') NOT NULL,
    preferred_payment_method ENUM('credit_card', 'e-wallet', 'blockchain_token') NULL DEFAULT NULL,
    brand_affiliation ENUM('pro', 'tourist', 'both') NULL DEFAULT NULL,
    green_driver_status BOOLEAN NOT NULL,
    priority_ev_spot_id VARCHAR(20) NULL DEFAULT NULL,
    client_segmentation ENUM('basic', 'regular', 'vip') NULL DEFAULT NULL,
    PRIMARY KEY(client_id),
    FOREIGN KEY(loyalty_tier_id) REFERENCES loyalty_tiers(loyalty_tier_id),
    FOREIGN KEY(priority_ev_spot_id) REFERENCES parking_spots(parking_spot_id)
);

CREATE TABLE phone_numbers(
    phone_id INT NOT NULL AUTO_INCREMENT,
    client_id VARCHAR(20) NOT NULL,
    phone_number VARCHAR(10) NOT NULL,
    is_primary BOOLEAN NOT NULL,
    PRIMARY KEY(phone_id),
    FOREIGN KEY(client_id) REFERENCES clients(client_id)
);

CREATE TABLE emails(
    email_id INT NOT NULL AUTO_INCREMENT,
    client_id VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    is_primary BOOLEAN NOT NULL,
    PRIMARY KEY(email_id),
    FOREIGN KEY(client_id) REFERENCES clients(client_id)
);

CREATE TABLE individual_commuter(
    client_id VARCHAR(20) NOT NULL,
    commute_pattern ENUM('weekday_peak', 'weekday_offpeak', 'weekday_evening', 'weekend_shopper', 'mixed_schedule', 'flexible_remote', 'early_bird', 'evening_leisure') NOT NULL,
    PRIMARY KEY(client_id),
    FOREIGN KEY(client_id) REFERENCES clients(client_id)
);

CREATE TABLE corporate_fleet_account(
    client_id VARCHAR(20) NOT NULL,
    company_name VARCHAR(100) NOT NULL,
    fleet_size INT NOT NULL,
    corporate_subscription_rate DECIMAL(10,2) NOT NULL,
    billing_cycle ENUM('monthly', 'quarterly', 'annually') NOT NULL,
    PRIMARY KEY(client_id),
    FOREIGN KEY(client_id) REFERENCES clients(client_id)
);

CREATE TABLE referral_bonuses(
    referral_bonus_id VARCHAR(20) NOT NULL,
    referring_client_id VARCHAR(20) NOT NULL,
    referred_client_id VARCHAR(20) NOT NULL,
    referred_client_brand ENUM('pro', 'tourist', 'both') NOT NULL,
    zone_of_first_parking_session_id VARCHAR(20) NULL DEFAULT NULL,
    PRIMARY KEY(referral_bonus_id),
    FOREIGN KEY(referring_client_id) REFERENCES clients(client_id),
    FOREIGN KEY(referred_client_id) REFERENCES clients(client_id),
    FOREIGN KEY(zone_of_first_parking_session_id) REFERENCES location_zones(location_zone_id)
);

CREATE TABLE parkpoints(
    parkpoints_transaction_id VARCHAR(20) NOT NULL,
    client_id VARCHAR(20) NOT NULL,
    referral_bonus_id VARCHAR(20) NULL DEFAULT NULL,
    parkpoints_transaction_type ENUM('earn', 'redeem') NOT NULL,
    parkpoints_amount INT NOT NULL,
    parkpoints_type ENUM('basic', 'elite') NOT NULL,
    parkpoints_transaction_datetime DATETIME NOT NULL,
    PRIMARY KEY(parkpoints_transaction_id),
    UNIQUE(referral_bonus_id),
    FOREIGN KEY(client_id) REFERENCES clients(client_id),
    FOREIGN KEY(referral_bonus_id) REFERENCES referral_bonuses(referral_bonus_id)
);

CREATE TABLE earns(
    parkpoints_transaction_id VARCHAR(20) NOT NULL,
    parkpoints_source ENUM('parking_session', 'referral_bonus', 'green_driver_bonus', 'off_peak', 'ev_charger', 'multi_vehicle') NOT NULL,
    PRIMARY KEY(parkpoints_transaction_id),
    FOREIGN KEY(parkpoints_transaction_id) REFERENCES parkpoints(parkpoints_transaction_id)
);

CREATE TABLE redeems(
    parkpoints_transaction_id VARCHAR(20) NOT NULL,
    parkpoints_redemption_type ENUM('free_parking', 'mobile_wallet_credit', 'premium_covered_spots_discounts', 'merchandise') NOT NULL,
    PRIMARY KEY(parkpoints_transaction_id),
    FOREIGN KEY(parkpoints_transaction_id) REFERENCES parkpoints(parkpoints_transaction_id)
);

CREATE TABLE vehicles(
    license_plate_number VARCHAR(30) NOT NULL,
    client_id VARCHAR(20) NOT NULL,
    vehicle_type ENUM('sedan', 'suv', 'motorbike', 'van', 'mpv') NULL DEFAULT NULL,
    is_ev BOOLEAN NOT NULL,
    PRIMARY KEY(license_plate_number),
    FOREIGN KEY(client_id) REFERENCES clients(client_id)
);

CREATE TABLE dynamic_pricing_rules(
    rule_id VARCHAR(20) NOT NULL,
    surcharge_percentage INT NULL DEFAULT NULL,
    space_type_affected SET('standard', 'premium_covered', 'ev_charger', 'motorbike', 'reserved') NULL DEFAULT NULL,
    effective_start_datetime DATETIME NULL DEFAULT NULL,
    PRIMARY KEY(rule_id)
);

CREATE TABLE applied_pricing_rules(
    parking_spot_id VARCHAR(20) NOT NULL,
    rule_id VARCHAR(20) NOT NULL,
    PRIMARY KEY(parking_spot_id, rule_id),
    FOREIGN KEY(parking_spot_id) REFERENCES parking_spots(parking_spot_id),
    FOREIGN KEY(rule_id) REFERENCES dynamic_pricing_rules(rule_id)
);

CREATE TABLE location_zone_affected(
    rule_id VARCHAR(20) NOT NULL,
    location_zone_id VARCHAR(20) NOT NULL,
    PRIMARY KEY(rule_id, location_zone_id),
    FOREIGN KEY(rule_id) REFERENCES dynamic_pricing_rules(rule_id),
    FOREIGN KEY(location_zone_id) REFERENCES location_zones(location_zone_id)
);

CREATE TABLE peak_hours(
    peak_hour_id VARCHAR(20) NOT NULL,
    start_time TIME NULL DEFAULT NULL,
    end_time TIME NULL DEFAULT NULL,
    days_of_weeks SET('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NULL DEFAULT NULL,
    PRIMARY KEY(peak_hour_id)
);

CREATE TABLE applied_peak_hours(
    rule_id VARCHAR(20) NOT NULL,
    peak_hour_id VARCHAR(20) NOT NULL,
    PRIMARY KEY(rule_id, peak_hour_id),
    FOREIGN KEY(rule_id) REFERENCES dynamic_pricing_rules(rule_id),
    FOREIGN KEY(peak_hour_id) REFERENCES peak_hours(peak_hour_id)
);

CREATE TABLE air_quality_routes(
    air_quality_route_id VARCHAR(20) NOT NULL,
    reserved_parking_spot_id VARCHAR(20) NOT NULL,
    route VARCHAR(300) NOT NULL,
    avoided_pollution VARCHAR(100) NOT NULL,
    PRIMARY KEY(air_quality_route_id),
    UNIQUE(reserved_parking_spot_id),
    FOREIGN KEY(reserved_parking_spot_id) REFERENCES parking_spots(parking_spot_id)
);

CREATE TABLE license_plate_recognitions(
    lpr_id VARCHAR(20) NOT NULL,
    manufacture_date DATE NOT NULL,
    PRIMARY KEY(lpr_id)
);

CREATE TABLE parking_sessions(
    parking_session_transaction_id VARCHAR(20) NOT NULL,
    lpr_id VARCHAR(20) NOT NULL,
    license_plate_number VARCHAR(30) NOT NULL,
    parking_spot_id VARCHAR(20) NOT NULL,
    start_datetime DATETIME NOT NULL,
    end_datetime DATETIME NULL DEFAULT NULL,    
    base_charge DECIMAL(7,2) NULL DEFAULT NULL,    
    dynamic_surcharge_percent INT NULL DEFAULT NULL,
    local_taxes_percent INT NULL DEFAULT NULL,
    total_discount_percent INT NULL DEFAULT NULL,
    corporate_subscription_discount_percent INT NULL DEFAULT NULL,
    loyalty_discount_percent INT NULL DEFAULT NULL,
    promotional_discount_percent INT NULL DEFAULT NULL,
    PRIMARY KEY(parking_session_transaction_id),
    FOREIGN KEY(lpr_id) REFERENCES license_plate_recognitions(lpr_id),
    FOREIGN KEY(license_plate_number) REFERENCES vehicles(license_plate_number),
    FOREIGN KEY(parking_spot_id) REFERENCES parking_spots(parking_spot_id)
);

CREATE TABLE lpr_failure_logs(
    lpr_failure_id VARCHAR(20) NOT NULL,
    lpr_id VARCHAR(20) NOT NULL,
    lpr_failure_on_session_id VARCHAR(20) NOT NULL,
    lpr_failure_datetime DATETIME NOT NULL,
    lpr_failure_reason ENUM('plate_not_detected', 'plate_no_entry_record', 'low_image_quality', 'plate_number_blocked', 'other') NOT NULL,
    PRIMARY KEY(lpr_failure_id),
    FOREIGN KEY(lpr_id) REFERENCES license_plate_recognitions(lpr_id),
    FOREIGN KEY(lpr_failure_on_session_id) REFERENCES parking_sessions(parking_session_transaction_id)
);

CREATE TABLE revenues(
    revenue_id VARCHAR(20) NOT NULL,
    revenue_amount DECIMAL(7,2) NOT NULL,
    revenue_type ENUM('parking_session', 'corporate_subscription', 'parkpoints_redemption', 'penalties_for_unauthorized_parking_in_reserved_spot') NOT NULL,
    parking_session_transaction_id VARCHAR(20) NULL DEFAULT NULL,
    client_id VARCHAR(20) NULL DEFAULT NULL,
    parkpoints_transaction_id VARCHAR(20) NULL DEFAULT NULL,
    PRIMARY KEY(revenue_id),
    UNIQUE(parking_session_transaction_id),
    UNIQUE(parkpoints_transaction_id),
    FOREIGN KEY(parking_session_transaction_id) REFERENCES parking_sessions(parking_session_transaction_id),
    FOREIGN KEY(client_id) REFERENCES clients(client_id),
    FOREIGN KEY(parkpoints_transaction_id) REFERENCES parkpoints(parkpoints_transaction_id)
);

CREATE TABLE personnels(
    personnel_id VARCHAR(20) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role ENUM('technician', 'attendant', 'finance_officer', 'zone_manager') NOT NULL,
    assigned_location_zone_id VARCHAR(20) NOT NULL,    
    PRIMARY KEY(personnel_id),
    FOREIGN KEY(assigned_location_zone_id) REFERENCES location_zones(location_zone_id)
);

CREATE TABLE technicians(
    personnel_id VARCHAR(20) NOT NULL,
    specialization VARCHAR(50) NOT NULL,
    PRIMARY KEY(personnel_id),
    FOREIGN KEY(personnel_id) REFERENCES personnels(personnel_id)
);

CREATE TABLE attendants(
    personnel_id VARCHAR(20) NOT NULL,
    shift_type VARCHAR(20) NOT NULL,
    PRIMARY KEY(personnel_id),
    FOREIGN KEY(personnel_id) REFERENCES personnels(personnel_id)
);

CREATE TABLE finance_officers(
    personnel_id VARCHAR(20) NOT NULL,
    department VARCHAR(50) NOT NULL,
    PRIMARY KEY(personnel_id),
    FOREIGN KEY(personnel_id) REFERENCES personnels(personnel_id)
);

CREATE TABLE zone_managers(
    personnel_id VARCHAR(20) NOT NULL,
    years_of_experience DECIMAL(3,2) NOT NULL,
    PRIMARY KEY(personnel_id),
    FOREIGN KEY(personnel_id) REFERENCES personnels(personnel_id)
);

CREATE TABLE proactive_maintenance_alerts(
    proactive_maintenance_alert_id VARCHAR(20) NOT NULL,
    sensor_id VARCHAR(20) NOT NULL,
    sensor_failure_probability INT NOT NULL,
    predicted_sensor_failure_datetime DATETIME NOT NULL,
    proactive_maintenance_alert_datetime DATETIME NOT NULL,
    PRIMARY KEY(proactive_maintenance_alert_id),
    FOREIGN KEY(sensor_id) REFERENCES sensors(sensor_id)
);

CREATE TABLE maintenance_actions(
    maintenance_action_id VARCHAR(20) NOT NULL,
    parking_spot_id VARCHAR(20) NULL DEFAULT NULL,
    lpr_id VARCHAR(20) NULL DEFAULT NULL,
    technician_id VARCHAR(20) NOT NULL,
    maintenance_action_work_order_datetime DATETIME NOT NULL,
    proactive_maintenance_alert_id VARCHAR(20) NULL DEFAULT NULL,
    maintenance_action_status ENUM('pending', 'in_progress', 'completed', 'cancelled') NOT NULL,
    maintenance_action_taken_datetime DATETIME NULL DEFAULT NULL,
    description_of_work VARCHAR(300) NULL DEFAULT NULL,
    PRIMARY KEY(maintenance_action_id),
    UNIQUE(proactive_maintenance_alert_id),
    FOREIGN KEY(parking_spot_id) REFERENCES parking_spots(parking_spot_id),
    FOREIGN KEY(lpr_id) REFERENCES license_plate_recognitions(lpr_id),
    FOREIGN KEY(technician_id) REFERENCES personnels(personnel_id),
    FOREIGN KEY(proactive_maintenance_alert_id) REFERENCES proactive_maintenance_alerts(proactive_maintenance_alert_id)
);

CREATE TABLE alert_trigger_by_maintenance_logs(
    proactive_maintenance_alert_id VARCHAR(20) NOT NULL,
    maintenance_action_id VARCHAR(20) NOT NULL,
    PRIMARY KEY(proactive_maintenance_alert_id, maintenance_action_id),
    FOREIGN KEY(proactive_maintenance_alert_id) REFERENCES proactive_maintenance_alerts(proactive_maintenance_alert_id),
    FOREIGN KEY(maintenance_action_id) REFERENCES maintenance_actions(maintenance_action_id)
);

CREATE TABLE spot_inspections(
    spot_inspection_id VARCHAR(20) NOT NULL,
    parking_spot_id VARCHAR(20) NOT NULL,
    attendant_id VARCHAR(20) NOT NULL,
    spot_inspection_result ENUM('pass', 'warning', 'requires_maintenance') NOT NULL,
    spot_inspection_datetime DATETIME NOT NULL,
    PRIMARY KEY(spot_inspection_id),
    FOREIGN KEY(parking_spot_id) REFERENCES parking_spots(parking_spot_id),
    FOREIGN KEY(attendant_id) REFERENCES personnels(personnel_id)
);

CREATE TABLE ai_models(
    ai_model_id VARCHAR(20) NOT NULL,
    ai_model_name VARCHAR(100) NOT NULL,
    ai_model_type VARCHAR(100) NOT NULL,
    PRIMARY KEY(ai_model_id)
);

CREATE TABLE weathers(
    weather_id VARCHAR(20) NOT NULL,
    weather_type VARCHAR(100) NOT NULL,
    weather_APIs VARCHAR(100) NOT NULL,
    location_zone_id VARCHAR(20) NOT NULL,
    start_datetime DATETIME NOT NULL,
    end_datetime DATETIME NOT NULL,
    PRIMARY KEY(weather_id),
    FOREIGN KEY(location_zone_id) REFERENCES location_zones(location_zone_id)
);

CREATE TABLE customer_support_chatbots(
    message_id VARCHAR(20) NOT NULL,
    message_content VARCHAR(500) NOT NULL,
    message_datetime DATETIME NOT NULL,
    client_id VARCHAR(20) NOT NULL,
    PRIMARY KEY(message_id),
    FOREIGN KEY(client_id) REFERENCES clients(client_id)
);

CREATE TABLE ai_model_outputs(
    ai_model_output_id VARCHAR(20) NOT NULL,
    ai_model_id VARCHAR(20) NOT NULL,
    weather_id VARCHAR(20) NULL DEFAULT NULL,
    output_content VARCHAR(1000) NOT NULL,
    output_type ENUM('predictive_maintenance', 'demand_forecasting', 'customer_segmentation', 'chatbot') NOT NULL,
    output_datetime DATETIME NOT NULL,
    predicted_demand_scores DECIMAL(7,2) NULL DEFAULT NULL,
    optimal_pricing_indices DECIMAL(7,2) NULL DEFAULT NULL,    
    PRIMARY KEY(ai_model_output_id),
    FOREIGN KEY(ai_model_id) REFERENCES ai_models(ai_model_id),
    FOREIGN KEY(weather_id) REFERENCES weathers(weather_id)
);

CREATE TABLE sensor_predictive_maintenance_outputs(
    ai_model_output_id VARCHAR(20) NOT NULL,
    sensor_id VARCHAR(20) NOT NULL,
    sensor_predicted_maintenance_datetime DATETIME NOT NULL,
    PRIMARY KEY(ai_model_output_id),
    FOREIGN KEY(ai_model_output_id) REFERENCES ai_model_outputs(ai_model_output_id),
    FOREIGN KEY(sensor_id) REFERENCES sensors(sensor_id)
);

CREATE TABLE lpr_predictive_maintenance_outputs(
    ai_model_output_id VARCHAR(20) NOT NULL,
    lpr_id VARCHAR(20) NOT NULL,
    lpr_predicted_maintenance_datetime DATETIME NOT NULL,
    PRIMARY KEY(ai_model_output_id),
    FOREIGN KEY(ai_model_output_id) REFERENCES ai_model_outputs(ai_model_output_id),
    FOREIGN KEY(lpr_id) REFERENCES license_plate_recognitions(lpr_id)
);

CREATE TABLE customer_segmentation_outputs(
    ai_model_output_id VARCHAR(20) NOT NULL,
    client_id VARCHAR(20) NOT NULL,
    PRIMARY KEY(ai_model_output_id),
    FOREIGN KEY(ai_model_output_id) REFERENCES ai_model_outputs(ai_model_output_id),
    FOREIGN KEY(client_id) REFERENCES clients(client_id)
);

CREATE TABLE demand_forecasting_outputs(
    ai_model_output_id VARCHAR(20) NOT NULL,
    parking_spot_id VARCHAR(20) NOT NULL,
    PRIMARY KEY(ai_model_output_id),
    FOREIGN KEY(ai_model_output_id) REFERENCES ai_model_outputs(ai_model_output_id),
    FOREIGN KEY(parking_spot_id) REFERENCES parking_spots(parking_spot_id)
);

CREATE TABLE chatbot_outputs(
    ai_model_output_id VARCHAR(20) NOT NULL,
    message_id VARCHAR(20) NOT NULL,
    PRIMARY KEY(ai_model_output_id),
    FOREIGN KEY(ai_model_output_id) REFERENCES ai_model_outputs(ai_model_output_id),
    FOREIGN KEY(message_id) REFERENCES customer_support_chatbots(message_id)
);

CREATE TABLE event_calendars(
    event_id VARCHAR(20) NOT NULL,
    event_name VARCHAR(100) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    location_zone_id VARCHAR(20) NOT NULL,
    start_datetime DATETIME NOT NULL,
    end_datetime DATETIME NOT NULL,
    PRIMARY KEY(event_id),
    FOREIGN KEY(location_zone_id) REFERENCES location_zones(location_zone_id)
);

CREATE TABLE multiple_event_sources(
    ai_model_output_id VARCHAR(20) NOT NULL,
    event_id VARCHAR(20) NOT NULL,
    PRIMARY KEY(ai_model_output_id, event_id),
    FOREIGN KEY(ai_model_output_id) REFERENCES ai_model_outputs(ai_model_output_id),
    FOREIGN KEY(event_id) REFERENCES event_calendars(event_id)
);

CREATE TABLE sensor_sources(
    ai_model_output_id VARCHAR(20) NOT NULL,
    sensor_id VARCHAR(20) NOT NULL,
    PRIMARY KEY(ai_model_output_id, sensor_id),
    FOREIGN KEY(ai_model_output_id) REFERENCES ai_model_outputs(ai_model_output_id),
    FOREIGN KEY(sensor_id) REFERENCES sensors(sensor_id)
);

CREATE TABLE lpr_sources(
    ai_model_output_id VARCHAR(20) NOT NULL,
    lpr_id VARCHAR(20) NOT NULL,
    PRIMARY KEY(ai_model_output_id, lpr_id),
    FOREIGN KEY(ai_model_output_id) REFERENCES ai_model_outputs(ai_model_output_id),
    FOREIGN KEY(lpr_id) REFERENCES license_plate_recognitions(lpr_id)
);

CREATE TABLE client_sources(
    ai_model_output_id VARCHAR(20) NOT NULL,
    client_id VARCHAR(20) NOT NULL,
    PRIMARY KEY(ai_model_output_id, client_id),
    FOREIGN KEY(ai_model_output_id) REFERENCES ai_model_outputs(ai_model_output_id),
    FOREIGN KEY(client_id) REFERENCES clients(client_id)
);

CREATE TABLE parking_spot_sources(
    ai_model_output_id VARCHAR(20) NOT NULL,
    parking_spot_id VARCHAR(20) NOT NULL,
    PRIMARY KEY(ai_model_output_id, parking_spot_id),
    FOREIGN KEY(ai_model_output_id) REFERENCES ai_model_outputs(ai_model_output_id),
    FOREIGN KEY(parking_spot_id) REFERENCES parking_spots(parking_spot_id)
);
INSERT INTO loyalty_tiers (loyalty_tier_id, tier_name, discount_percentage, min_parkpoints_earned_required) VALUES
('1', 'bronze', 0, 0),
('2', 'silver', 0, 1000),
('3', 'gold', 5, 2000),
('4', 'elite', 5, 3000);

INSERT INTO sensors (sensor_id, sensor_status, manufacture_date) VALUES
('S1', 'operational', '2023-01-15'),
('S2', 'operational', '2023-02-20'),
('S3', 'need_calibration', '2023-03-10'),
('S4', 'offline', '2023-04-05'),
('S5', 'offline', '2023-05-12'),
('S6', 'offline', '2023-06-18'),
('S7', 'offline', '2023-07-22'),
('S8', 'operational', '2023-08-30'),
('S9', 'need_calibration', '2023-09-14'),
('S10', 'operational', '2023-10-25'),
('S11', 'operational', '2023-11-08'),
('S12', 'operational', '2023-12-16'),
('S13', 'operational', '2024-01-20'),
('S14', 'need_calibration', '2024-02-11'),
('S15', 'operational', '2024-03-19'),
('S16', 'operational', '2024-04-23'),
('S17', 'operational', '2024-05-07'),
('S18', 'offline', '2024-06-14'),
('S19', 'operational', '2024-07-28'),
('S20', 'operational', '2024-08-03'),
('S21', 'operational', '2024-09-12'),
('S22', 'operational', '2024-10-18'),
('S23', 'need_calibration', '2023-01-25'),
('S24', 'operational', '2023-02-28'),
('S25', 'operational', '2023-03-15'),
('S26', 'operational', '2023-04-20'),
('S27', 'offline', '2023-05-25'),
('S28', 'operational', '2023-06-30'),
('S29', 'operational', '2023-07-15'),
('S30', 'operational', '2023-08-20'),
('S31', 'operational', '2023-09-25'),
('S32', 'need_calibration', '2023-10-30'),
('S33', 'operational', '2023-11-15'),
('S34', 'operational', '2023-12-20'),
('S35', 'operational', '2024-01-25'),
('S36', 'operational', '2024-02-28'),
('S37', 'offline', '2024-03-15'),
('S38', 'operational', '2024-04-20'),
('S39', 'operational', '2024-05-25'),
('S40', 'operational', '2024-06-30'),
('S41', 'need_calibration', '2024-07-15'),
('S42', 'operational', '2024-08-20'),
('S43', 'operational', '2024-09-25'),
('S44', 'operational', '2024-10-30'),
('S45', 'operational', '2023-01-10'),
('S46', 'offline', '2023-02-15'),
('S47', 'operational', '2023-03-20'),
('S48', 'operational', '2023-04-25'),
('S49', 'need_calibration', '2023-05-30'),
('S50', 'operational', '2023-06-15');
INSERT INTO location_zones (location_zone_id, location_zone_name, air_quality_index, pm25_value, pm10_value, co_value, co2_value, no2_value, o3_value, so2_value) VALUES
('ZN1', 'kl_sentral', 72.00, 25.40, 40.80, 0.80, 420.00, 18.20, 30.10, 4.50),
('ZN2', 'jalan_ampang', 58.00, 18.90, 28.30, 0.50, 390.00, 14.60, 35.70, 3.80),
('ZN3', 'bukit_bintang', 42.00, 10.50, 15.20, 0.30, 370.00, 9.10, 40.80, 2.90),
('ZN4', 'cyberjaya', 96.00, 33.10, 52.70, 1.10, 460.00, 22.80, 25.40, 6.20),
('ZN5', 'the_gradens_mall', 65.00, 20.70, 31.60, 0.60, 400.00, 15.30, 33.50, 4.10);

INSERT INTO parking_spots (parking_spot_id, sensor_id, location_zone_id, space_type, reserved_license_plate_number, standard_hourly_rate, site_tier, real_time_demand_rating, predicted_current_demand_rating) VALUES
('PS1', 'S1', 'ZN1', 'ev_charger', 'VQH1234', 5.00, 'tier_3', 'moderate', 'moderate'),
('PS2', 'S2', 'ZN1', 'standard', NULL, 4.00, 'tier_2', 'high', 'high'),
('PS3', 'S3', 'ZN1', 'ev_charger', 'VZX7766', 6.00, 'tier_3', 'moderate', 'moderate'),
('PS4', 'S4', 'ZN1', 'reserved', 'WNM8821', 6.00, 'tier_3', 'low', 'moderate'),
('PS5', 'S5', 'ZN1', 'standard', NULL, 4.00, 'tier_2', 'high', 'high'),
('PS6', 'S6', 'ZN1', 'ev_charger', 'BLT5678', 5.00, 'tier_3', 'moderate', 'moderate'),
('PS7', 'S7', 'ZN1', 'standard', NULL, 4.00, 'tier_2', 'moderate', 'high'),
('PS8', 'S8', 'ZN1', 'premium_covered', 'LHY5589', 8.00, 'tier_3', 'low', 'low'),
('PS9', 'S9', 'ZN1', 'motorbike', NULL, 3.80, 'tier_1', 'high', 'high'),
('PS10', 'S10', 'ZN1', 'motorbike', NULL, 3.50, 'tier_1', 'low', 'moderate'),
('PS11', 'S11', 'ZN2', 'ev_charger', 'JQK3219', 6.00, 'tier_3', 'moderate', 'moderate'),
('PS12', 'S12', 'ZN2', 'standard', NULL, 4.00, 'tier_2', 'high', 'high'),
('PS13', 'S13', 'ZN2', 'ev_charger', 'WAD5532', 6.00, 'tier_3', 'moderate', 'moderate'),
('PS14', 'S14', 'ZN2', 'reserved', 'PNF8823', 6.00, 'tier_3', 'low', 'moderate'),
('PS15', 'S15', 'ZN2', 'standard', NULL, 4.00, 'tier_2', 'high', 'high'),
('PS16', 'S16', 'ZN2', 'ev_charger', 'VLB2197', 5.00, 'tier_3', 'moderate', 'moderate'),
('PS17', 'S17', 'ZN2', 'standard', NULL, 4.00, 'tier_2', 'moderate', 'high'),
('PS18', 'S18', 'ZN2', 'premium_covered', 'WCT4408', 8.00, 'tier_3', 'low', 'low'),
('PS19', 'S19', 'ZN2', 'motorbike', NULL, 3.80, 'tier_1', 'high', 'high'),
('PS20', 'S20', 'ZN2', 'motorbike', NULL, 3.50, 'tier_1', 'low', 'moderate'),
('PS21', 'S21', 'ZN3', 'ev_charger', 'JLT9982', 6.00, 'tier_3', 'moderate', 'moderate'),
('PS22', 'S22', 'ZN3', 'standard', NULL, 4.00, 'tier_2', 'high', 'high'),
('PS23', 'S23', 'ZN3', 'ev_charger', 'NBM7736', 6.00, 'tier_3', 'moderate', 'moderate'),
('PS24', 'S24', 'ZN3', 'reserved', 'WYY3207', 6.00, 'tier_3', 'low', 'moderate'),
('PS25', 'S25', 'ZN3', 'ev_charger', NULL, 4.00, 'tier_2', 'high', 'high'),
('PS26', 'S26', 'ZN3', 'ev_charger', 'BLS2211', 5.00, 'tier_3', 'moderate', 'moderate'),
('PS27', 'S27', 'ZN3', 'standard', NULL, 4.00, 'tier_2', 'moderate', 'high'),
('PS28', 'S28', 'ZN3', 'premium_covered', 'NBM7736', 8.00, 'tier_3', 'low', 'low'),
('PS29', 'S29', 'ZN3', 'motorbike', NULL, 3.80, 'tier_1', 'high', 'high'),
('PS30', 'S30', 'ZN3', 'motorbike', NULL, 3.50, 'tier_1', 'low', 'moderate'),
('PS31', 'S31', 'ZN4', 'ev_charger', 'VKP6624', 6.00, 'tier_3', 'moderate', 'moderate'),
('PS32', 'S32', 'ZN4', 'standard', NULL, 4.00, 'tier_2', 'high', 'high'),
('PS33', 'S33', 'ZN4', 'ev_charger', 'WNB8876', 6.00, 'tier_3', 'moderate', 'moderate'),
('PS34', 'S34', 'ZN4', 'reserved', 'JQS4392', 6.00, 'tier_3', 'low', 'moderate'),
('PS35', 'S35', 'ZN4', 'standard', NULL, 4.00, 'tier_2', 'high', 'high'),
('PS36', 'S36', 'ZN4', 'ev_charger', 'PLY6723', 5.00, 'tier_3', 'moderate', 'moderate'),
('PS37', 'S37', 'ZN4', 'standard', 'NRK1109', 4.00, 'tier_2', 'moderate', 'high'),
('PS38', 'S38', 'ZN4', 'premium_covered', 'VKT5564', 8.00, 'tier_3', 'low', 'low'),
('PS39', 'S39', 'ZN4', 'motorbike', NULL, 3.80, 'tier_1', 'high', 'high'),
('PS40', 'S40', 'ZN4', 'motorbike', NULL, 3.50, 'tier_1', 'low', 'moderate'),
('PS41', 'S41', 'ZN5', 'ev_charger', 'NDK3342', 6.00, 'tier_3', 'moderate', 'moderate'),
('PS42', 'S42', 'ZN5', 'standard', NULL, 4.00, 'tier_2', 'high', 'high'),
('PS43', 'S43', 'ZN5', 'ev_charger', 'JLV8821', 6.00, 'tier_3', 'moderate', 'moderate'),
('PS44', 'S44', 'ZN5', 'reserved', 'PKM5539', 6.00, 'tier_3', 'low', 'moderate'),
('PS45', 'S45', 'ZN5', 'standard', NULL, 4.00, 'tier_2', 'high', 'high'),
('PS46', 'S46', 'ZN5', 'ev_charger', 'WQL7861', 5.00, 'tier_3', 'moderate', 'moderate'),
('PS47', 'S47', 'ZN5', 'standard', NULL, 4.00, 'tier_2', 'moderate', 'high'),
('PS48', 'S48', 'ZN5', 'premium_covered', 'WTC9027', 8.00, 'tier_3', 'low', 'low'),
('PS49', 'S49', 'ZN5', 'motorbike', NULL, 3.80, 'tier_1', 'high', 'high'),
('PS50', 'S50', 'ZN5', 'motorbike', NULL, 3.50, 'tier_1', 'low', 'moderate');

INSERT INTO clients (client_id, full_name, referral_source, loyalty_tier_id, parkpoints_balance, parkpoints_elite_balance, business_relationship_type, preferred_payment_method, brand_affiliation, green_driver_status, priority_ev_spot_id, client_segmentation) VALUES
('C1', 'Alice Tan', 'social_media', '3', 500, 150, 'individual_commuter', NULL, 'pro', 1, 'PS1', 'basic'),
('C2', 'Benjamin Lim', 'google_ad', '1', 0, 0, 'individual_commuter', 'credit_card', 'tourist', 0, 'PS3', 'basic'),
('C3', 'Chloe Wong', NULL, '3', 2000, 500, 'corporate_fleet_account', 'e-wallet', 'pro', 1, 'PS6', 'regular'),
('C4', 'Daniel Lee', 'google_ad', '4', 3000, 1200, 'individual_commuter', 'credit_card', 'tourist', 0, 'PS11', 'vip'),
('C5', 'Elaine Ng', 'social_media', '2', 1000, 0, 'corporate_fleet_account', 'e-wallet', NULL, 1, 'PS16', 'basic'),
('C6', 'Farid Ahmad', 'social_media', '4', 4000, 800, 'individual_commuter', 'e-wallet', 'pro', 1, NULL, 'vip'),
('C7', 'Grace Lim', NULL, '3', 2600, 400, 'individual_commuter', 'blockchain_token', 'pro', 0, NULL, 'regular'),
('C8', 'Isabel Goh', NULL, '2', 1500, 80, 'corporate_fleet_account', NULL, 'tourist', 0, 'PS21', 'basic'),
('C9', 'Haziq', 'google_ad', '2', 1080, 120, 'corporate_fleet_account', 'credit_card', NULL, 0, NULL, 'basic'),
('C10', 'Jason Chong', NULL, '1', 980, 0, 'individual_commuter', NULL, NULL, 1, 'PS41', 'basic'),
('C11', 'Aaron Lee', 'google_ad', '3', 3100, 900, 'corporate_fleet_account', 'blockchain_token', 'pro', 1, 'PS31', 'regular'),
('C12', 'Bella Tan', 'social_media', '3', 2900, 700, 'corporate_fleet_account', 'blockchain_token', 'pro', 1, 'PS36', 'regular'),
('C13', 'Darren Khoo', 'google_ad', '4', 4200, 1200, 'corporate_fleet_account', 'blockchain_token', 'pro', 1, 'PS33', 'vip'),
('C14', 'Emily Ho', 'social_media', '3', 3600, 800, 'individual_commuter', 'blockchain_token', 'tourist', 1, NULL, 'regular'),
('C15', 'Nur Aisyah', 'google_ad', '3', 3400, 700, 'individual_commuter', 'blockchain_token', 'both', 0, 'PS21', 'regular'),
('C16', 'Leonard Tan', NULL, '2', 2800, 400, 'corporate_fleet_account', 'blockchain_token', 'pro', 1, 'PS12', 'regular'),
('C17', 'Mei Ling', NULL, '3', 2650, 450, 'individual_commuter', 'blockchain_token', 'tourist', 0, NULL, 'basic'),
('C18', 'Raj Kumar', 'social_media', '4', 3900, 1100, 'corporate_fleet_account', 'blockchain_token', 'both', 1, 'PS25', 'vip'),
('C19', 'Siti Nur', 'google_ad', '2', 2950, 500, 'individual_commuter', 'blockchain_token', 'pro', 1, 'PS42', 'regular');

INSERT INTO phone_numbers (client_id, phone_number, is_primary) VALUES
('C1', '0123456789', 1),
('C2', '0105566778', 1),
('C4', '0132244668', 1),
('C6', '0127788990', 1),
('C7', '0179988776', 1),
('C8', '0147788123', 1),
('C10', '0162233445', 1),
('C11', '0191112233', 1),
('C12', '0162223344', 1),
('C14', '0174455667', 1),
('C15', '0137788991', 1),
('C17', '0129988776', 1),
('C18', '0191122334', 1),
('C19', '0146677002', 1);

INSERT INTO emails (client_id, email, is_primary) VALUES
('C1', 'alice.tan@gmail.com', 1),
('C2', 'ben.lim@gmail.com', 1),
('C3', 'chloe.wong@gmail.com', 1),
('C4', 'daniel.lee@gmail.com', 1),
('C5', 'elaine.ng@gmail.com', 1),
('C6', 'farid.ahmad@gmail.com', 1),
('C7', 'grace.lim@gmail.com', 1),
('C8', 'isabel.goh@gmail.com', 1),
('C9', 'haziq.rah@gmail.com', 1),
('C10', 'jason.ch@gmail.com', 1),
('C11', 'aaron.lee@gmail.com', 1),
('C12', 'bella.tan@gmail.com', 1),
('C13', 'darren.khoo@gmail.com', 1),
('C14', 'emily.ho@gmail.com', 1),
('C15', 'nur.aisyah@gmail.com', 1),
('C16', 'leonard.tan@gmail.com', 1),
('C17', 'mei.ling.client@gmail.com', 1),
('C18', 'raj.kumar.client@gmail.com', 1),
('C19', 'siti.nur.client@gmail.com', 1);

INSERT INTO individual_commuter (client_id, commute_pattern) VALUES
('C1', 'weekday_peak'),
('C2', 'weekday_offpeak'),
('C4', 'early_bird'),
('C6', 'flexible_remote'),
('C7', 'mixed_schedule'),
('C10', 'weekend_shopper'),
('C14', 'weekday_peak'),
('C15', 'weekday_offpeak'),
('C17', 'flexible_remote'),
('C19', 'weekend_shopper');

INSERT INTO corporate_fleet_account (client_id, company_name, fleet_size, corporate_subscription_rate, billing_cycle) VALUES
('C3', 'TechCorp Solutions Sdn Bhd', 25, 5000.00, 'monthly'),
('C5', 'Green Energy Malaysia', 40, 8500.00, 'quarterly'),
('C8', 'Logistics Plus Sdn Bhd', 60, 12000.00, 'annually'),
('C9', 'Digital Services Co', 35, 7200.00, 'monthly'),
('C11', 'Metro Logistics Sdn Bhd', 55, 9500.00, 'monthly'),
('C12', 'EcoCity Mobility Sdn Bhd', 40, 7800.00, 'quarterly'),
('C13', 'Urban Mobility Sdn Bhd', 70, 15000.00, 'monthly'),
('C16', 'MetroRide Logistics Sdn Bhd', 45,  9000.00, 'monthly'),
('C18', 'CityShuttle Services Sdn Bhd', 55, 13500.00, 'quarterly');

INSERT INTO referral_bonuses (referral_bonus_id, referring_client_id, referred_client_id, referred_client_brand, zone_of_first_parking_session_id) VALUES
('RB1', 'C1', 'C2', 'pro', 'ZN3'),
('RB2', 'C2', 'C4', 'tourist', 'ZN5'),
('RB3', 'C3', 'C7', 'pro', 'ZN2'),
('RB4', 'C5', 'C9', 'pro', 'ZN1'),
('RB5', 'C7', 'C10', 'tourist', 'ZN4'),
('RB6', 'C9', 'C6', 'both', 'ZN1'),
('RB7', 'C4', 'C8', 'tourist', 'ZN2'),
('RB8', 'C10', 'C1', 'tourist', 'ZN3'),
('RB9', 'C6', 'C3', 'both', 'ZN4'),
('RB10', 'C8', 'C5', 'pro', 'ZN5');

INSERT INTO parkpoints (parkpoints_transaction_id, client_id, referral_bonus_id, parkpoints_transaction_type, parkpoints_amount, parkpoints_type, parkpoints_transaction_datetime) VALUES
('PT1', 'C1', 'RB1', 'earn', 200, 'basic', '2025-10-10 09:45:32'),
('PT2', 'C2', 'RB2', 'earn', 150, 'basic', '2025-10-11 14:22:10'),
('PT3', 'C3', 'RB3', 'earn', 500, 'elite', '2025-10-12 18:10:45'),
('PT4', 'C4', NULL, 'earn', 300, 'basic', '2025-10-13 07:55:20'),
('PT5', 'C5', 'RB4', 'earn', 800, 'elite', '2025-10-14 16:40:58'),
('PT6', 'C6', NULL, 'redeem', -100, 'basic', '2025-10-15 11:12:47'),
('PT7', 'C7', 'RB5', 'earn', 400, 'elite', '2025-10-16 13:30:19'),
('PT8', 'C8', NULL, 'redeem', -250, 'basic', '2025-10-17 10:05:50'),
('PT9', 'C9', 'RB6', 'earn', 1000, 'elite', '2025-10-18 20:44:31'),
('PT10', 'C10', NULL, 'redeem', -200, 'basic', '2025-10-19 09:12:16');

INSERT INTO earns (parkpoints_transaction_id, parkpoints_source) VALUES
('PT1', 'parking_session'),
('PT2', 'referral_bonus'),
('PT3', 'green_driver_bonus'),
('PT4', 'parking_session'),
('PT5', 'off_peak'),
('PT7', 'ev_charger'),
('PT9', 'multi_vehicle');

INSERT INTO redeems (parkpoints_transaction_id, parkpoints_redemption_type) VALUES
('PT6', 'free_parking'),
('PT8', 'mobile_wallet_credit'),
('PT10', 'premium_covered_spots_discounts');

INSERT INTO vehicles (license_plate_number, client_id, vehicle_type, is_ev) VALUES
('VQH1234', 'C1', 'sedan', 1),
('BLT5678', 'C2', 'motorbike', 0),
('WNM8821', 'C3', 'suv', 1),
('JDK4455', 'C4', 'sedan', 0),
('PEA9910', 'C5', 'sedan', 1),
('KTR3344', 'C6', 'van', 0),
('VZX7766', 'C7', 'suv', 1),
('MLP2201', 'C8', 'mpv', 0),
('LHY5589', 'C9', 'sedan', 1),
('QAZ9012', 'C10', 'sedan', 1),
('JQK3219', 'C11', 'suv', 1),
('WAD5532', 'C12', 'suv', 1),
('PNF8823', 'C13', 'van', 0),
('VLB2197', 'C14', 'sedan', 0),
('WCT4408', 'C15', 'sedan', 1),
('JLT9982', 'C16', 'mpv', 1),
('NBM7736', 'C17', 'van', 0),
('WYY3207', 'C18', 'motorbike', 0),
('BLS2211', 'C19', 'sedan', 0),
('NBM7735', 'C10', 'suv', 1),
('VKP6624', 'C1', 'suv', 1),
('WNB8876', 'C2', 'sedan', 0),
('JQS4392', 'C3', 'mpv', 1),
('PLY6723', 'C4', 'sedan', 1),
('VKT5564', 'C5', 'sedan', 1),
('NDK3342', 'C6', 'motorbike', 0),
('JLV8821', 'C7', 'sedan', 1),
('PKM5539', 'C8', 'mpv', 1),
('WQL7861', 'C9', 'van', 0),
('WTC9027', 'C10', 'van', 0),
('NRK1109', 'C11', 'sedan', 1),
('JTH8801', 'C12', 'mpv', 1),
('WXL6888', 'C13', 'suv', 1);

INSERT INTO dynamic_pricing_rules (rule_id, surcharge_percentage, space_type_affected, effective_start_datetime) VALUES
('R1', 20, 'ev_charger', '2025-10-01 00:00:00'),
('R2', 10, 'standard', '2025-10-05 00:00:00'),
('R3', 15, 'standard', '2025-10-07 00:00:00'),
('R4', 25, 'premium_covered', '2025-10-10 00:00:00'),
('R5', 5, 'motorbike', '2025-10-12 00:00:00'),
('R6', 30, 'ev_charger', '2025-10-15 00:00:00'),
('R7', 8, 'motorbike', '2025-10-18 00:00:00'),
('R8', 12, 'standard', '2025-10-20 00:00:00'),
('R9', 18, 'ev_charger', '2025-10-25 00:00:00'),
('R10', 22, 'reserved', '2025-10-28 00:00:00');

INSERT INTO applied_pricing_rules (parking_spot_id, rule_id) VALUES
('PS1', 'R1'),
('PS2', 'R2'),
('PS3', 'R6'),
('PS4', 'R10'),
('PS5', 'R3'),
('PS6', 'R9'),
('PS7', 'R8'),
('PS8', 'R4'),
('PS9', 'R5'),
('PS10', 'R7');

INSERT INTO location_zone_affected (rule_id, location_zone_id) VALUES
('R1', 'ZN1'),
('R2', 'ZN5'),
('R3', 'ZN4'),
('R4', 'ZN1'),
('R5', 'ZN2'),
('R6', 'ZN3'),
('R7', 'ZN2'),
('R8', 'ZN3'),
('R9', 'ZN1'),
('R10', 'ZN2');

INSERT INTO peak_hours (peak_hour_id, start_time, end_time, days_of_weeks) VALUES
('PH1', '07:00:00', '09:00:00', 'Monday'),
('PH2', '17:00:00', '23:00:00', 'Friday'),
('PH3', '11:30:00', '13:30:00', 'Tuesday'),
('PH4', '10:00:00', '12:00:00', 'Wednesday'),
('PH5', '14:00:00', '16:00:00', 'Saturday'),
('PH6', '08:00:00', '10:00:00', 'Thursday'),
('PH7', '18:00:00', '21:00:00', 'Saturday'),
('PH8', '06:30:00', '08:30:00', 'Monday'),
('PH9', '12:00:00', '14:00:00', 'Sunday'),
('PH10', '19:00:00', '22:00:00', 'Friday');

INSERT INTO applied_peak_hours (rule_id, peak_hour_id) VALUES
('R1', 'PH1'),
('R2', 'PH2'),
('R3', 'PH3'),
('R4', 'PH7'),
('R5', 'PH4'),
('R6', 'PH6'),
('R7', 'PH9'),
('R8', 'PH8'),
('R9', 'PH10'),
('R10', 'PH5');

INSERT INTO air_quality_routes (air_quality_route_id, reserved_parking_spot_id, route, avoided_pollution) VALUES
('AQ1', 'PS1', 'From Gate A to Zone 1', 'industrial haze'),
('AQ2', 'PS3', 'From Gate B to Zone 3', 'vehicle exhaust'),
('AQ3', 'PS5', 'From Gate C to Zone 2', 'construction dust'),
('AQ4', 'PS6', 'From Gate D to Zone 5', 'carbon monoxide'),
('AQ5', 'PS8', 'From Gate A to Basement Zone', 'roadside smoke'),
('AQ6', 'PS10', 'From Gate E to Rooftop Area', 'exhaust emissions'),
('AQ7', 'PS4', 'From Gate F to Zone 4', 'factory fumes'),
('AQ8', 'PS2', 'From Gate G to Zone 6', 'engine idling'),
('AQ9', 'PS9', 'From Gate H to Zone 2', 'urban haze'),
('AQ10', 'PS7', 'From Gate I to VIP Zone', 'traffic pollution');

INSERT INTO license_plate_recognitions (lpr_id, manufacture_date) VALUES
('LPR1', '2023-01-15'),
('LPR2', '2023-02-20'),
('LPR3', '2023-03-25'),
('LPR4', '2023-04-30'),
('LPR5', '2023-05-15'),
('LPR6', '2023-06-20'),
('LPR7', '2023-07-25'),
('LPR8', '2023-08-30'),
('LPR9', '2023-09-15'),
('LPR10', '2023-10-20'),
('LPR11', '2023-11-25');

INSERT INTO parking_sessions (parking_session_transaction_id, lpr_id, license_plate_number, parking_spot_id, start_datetime, end_datetime, base_charge, dynamic_surcharge_percent, local_taxes_percent, total_discount_percent, corporate_subscription_discount_percent, loyalty_discount_percent, promotional_discount_percent) VALUES
('PST1', 'LPR1', 'VQH1234', 'PS1', '2025-10-10 08:00:00', '2025-10-10 12:00:00', 20.00, 20, 6, 8, 2, 5, 1),
('PST2', 'LPR2', 'BLT5678', 'PS26', '2025-10-11 09:30:00', '2025-10-11 11:00:00', 6.30, 8, 6, 3, 1, 1, 1),
('PST3', 'LPR3', 'WNM8821', 'PS24', '2025-10-12 14:00:00', '2025-10-12 17:00:00', 16.50, 12, 6, 4, 2, 1, 1),
('PST4', 'LPR4', 'JDK4455', 'PS25', '2025-10-13 07:00:00', '2025-10-13 08:30:00', 5.25, 5, 6, 2, 1, 0, 0),
('PST5', 'LPR5', 'PEA9910', 'PS45', '2025-10-14 18:00:00', '2025-10-14 21:00:00', 24.00, 10, 6, 5, 3, 1, 1),
('PST6', 'LPR6', 'KTR3344', 'PS7', '2025-10-15 12:00:00', '2025-10-15 13:30:00', 9.75, 10, 6, 4, 2, 1, 1),
('PST7', 'LPR7', 'VZX7766', 'PS23', '2025-10-16 10:00:00', '2025-10-16 12:00:00', 11.60, 10, 6, 5, 2, 2, 1),
('PST8', 'LPR8', 'MLP2201', 'PS9', '2025-10-17 13:00:00', '2025-10-17 15:00:00', 16.00, 8, 6, 4, 2, 1, 1),
('PST9', 'LPR9', 'LHY5589', 'PS18', '2025-10-18 09:00:00', '2025-10-18 11:30:00', 16.25, 10, 6, 5, 2, 2, 1),
('PST10', 'LPR10', 'QAZ9012', 'PS31', '2025-10-19 08:30:00', '2025-10-19 09:30:00', 3.80, 5, 6, 2, 1, 0, 0),
('PST11', 'LPR11', 'NRK1109', 'PS7', '2025-10-20 10:00:00', '2025-10-20 13:00:00', 15.00, 20, 6, 5, 0, 5, 0),
('PST12', 'LPR3',  'WNM8821', 'PS5',  '2025-10-20 08:30:00', '2025-10-20 10:00:00',  6.00, 10, 6, 3, 1, 1, 1),   
('PST13', 'LPR4',  'JDK4455', 'PS3', '2025-10-21 09:00:00', '2025-10-21 11:30:00', 18.00, 12, 6, 4, 2, 2, 1),   
('PST14', 'LPR5',  'PEA9910', 'PS31', '2025-10-22 14:00:00', '2025-10-22 16:00:00', 16.00, 15, 6, 5, 2, 2, 1),   
('PST15', 'LPR6',  'KTR3344', 'PS42', '2025-10-23 11:30:00', '2025-10-23 13:00:00', 12.00, 10, 6, 4, 1, 1, 1),
('PST16', 'LPR11', 'VZX7766', 'PS12', '2025-10-24 08:00:00', '2025-10-24 10:30:00', 18.00, 12, 6, 5, 2, 2, 1),
('PST17', 'LPR1', 'WQL7861', 'PS15', '2025-10-24 09:30:00', '2025-10-24 11:00:00', 10.50, 8, 6, 3, 1, 1, 1),
('PST18', 'LPR4', 'JQS4392', 'PS9', '2025-10-25 14:00:00', '2025-10-25 17:30:00', 21.00, 15, 6, 5, 2, 2, 1),
('PST19', 'LPR3', 'JLV8821', 'PS21', '2025-10-26 07:30:00', '2025-10-26 09:00:00', 7.25, 5, 6, 2, 1, 0, 0),
('PST20', 'LPR2', 'PKM5539', 'PS33', '2025-10-26 18:00:00', '2025-10-26 20:00:00', 13.50, 10, 6, 4, 1, 1, 1),
('PST21', 'LPR8', 'NBM7735', 'PS36', '2025-10-27 08:00:00', '2025-10-27 12:00:00', 22.00, 20, 6, 5, 2, 2, 1),
('PST22', 'LPR8', 'JTH8801', 'PS48', '2025-10-27 13:00:00', '2025-10-27 15:00:00', 15.00, 10, 6, 4, 2, 1, 1),
('PST23', 'LPR9', 'NRK1109', 'PS35', '2025-10-28 09:00:00', '2025-10-28 11:30:00', 16.00, 12, 6, 3, 1, 2, 1),
('PST24', 'LPR10', 'JTH8801', 'PS20', '2025-10-28 14:00:00', '2025-10-28 17:00:00', 18.50, 15, 6, 5, 2, 2, 1),
('PST25', 'LPR1', 'WXL6888', 'PS41', '2025-10-29 08:30:00', '2025-10-29 10:30:00', 12.00, 10, 6, 4, 1, 1, 1),
('PST26', 'LPR2', 'BLS2211', 'PS11', '2025-10-29 12:00:00', '2025-10-29 13:30:00', 8.00, 8, 6, 3, 1, 1, 1),
('PST27', 'LPR5', 'VKT5564', 'PS8', '2025-10-30 10:00:00', '2025-10-30 12:00:00', 14.50, 10, 6, 5, 2, 2, 1),
('PST28', 'LPR8', 'PLY6723', 'PS32', '2025-10-30 13:30:00', '2025-10-30 16:00:00', 19.00, 12, 6, 4, 2, 1, 1),
('PST29', 'LPR11', 'JLV8821', 'PS14', '2025-10-31 08:00:00', '2025-10-31 10:00:00', 12.00, 10, 6, 3, 1, 1, 0),
('PST30', 'LPR9', 'NDK3342', 'PS9', '2025-10-31 11:00:00', '2025-10-31 12:30:00', 6.50, 5, 6, 2, 1, 0, 0),
('PST31', 'LPR1', 'VZX7766', 'PS12', '2025-11-04 08:00:00', '2025-11-04 10:30:00', 18.00, 12, 6, 5, 2, 2, 1),
('PST32', 'LPR11', 'WQL7861', 'PS15', '2025-11-08 09:30:00', '2025-11-08 11:00:00', 10.50, 8, 6, 3, 1, 1, 1),
('PST33', 'LPR10', 'JQS4392', 'PS19', '2025-11-08 14:00:00', '2025-11-08 17:30:00', 21.00, 15, 6, 5, 2, 2, 1),
('PST34', 'LPR5', 'JLV8821', 'PS21', '2025-11-11 07:30:00', '2025-11-11 09:00:00', 7.25, 5, 6, 2, 1, 0, 0),
('PST35', 'LPR6', 'PKM5539', 'PS43', '2025-11-12 18:00:00', '2025-11-12 20:00:00', 13.50, 10, 6, 4, 1, 1, 1),
('PST36', 'LPR10', 'NBM7735', 'PS26', '2025-11-12 08:00:00', '2025-11-12 12:00:00', 22.00, 20, 6, 5, 2, 2, 1),
('PST37', 'LPR11', 'JTH8801', 'PS38', '2025-11-13 13:00:00', '2025-11-13 15:00:00', 15.00, 10, 6, 4, 2, 1, 1),
('PST38', 'LPR9', 'NRK1109', 'PS25', '2025-11-15 09:00:00', '2025-11-15 11:30:00', 16.00, 12, 6, 3, 1, 2, 1),
('PST39', 'LPR2', 'JTH8801', 'PS40', '2025-11-16 14:00:00', '2025-11-16 17:00:00', 18.50, 15, 6, 5, 2, 2, 1),
('PST40', 'LPR1', 'WXL6888', 'PS21', '2025-11-20 08:30:00', '2025-11-20 10:30:00', 12.00, 10, 6, 4, 1, 1, 1),
('PST41', 'LPR5', 'BLS2211', 'PS11', '2025-11-21 12:00:00', '2025-11-21 13:30:00', 8.00, 8, 6, 3, 1, 1, 1),
('PST42', 'LPR3', 'VKT5564', 'PS40', '2025-11-21 10:00:00', '2025-11-21 12:00:00', 14.50, 10, 6, 5, 2, 2, 1),
('PST43', 'LPR7', 'PLY6723', 'PS32', '2025-11-22 13:30:00', '2025-11-22 16:00:00', 19.00, 12, 6, 4, 2, 1, 1),
('PST44', 'LPR11', 'JLV8821', 'PS34', '2025-11-25 08:00:00', '2025-11-25 10:00:00', 12.00, 10, 6, 3, 1, 1, 0),
('PST45', 'LPR10', 'NDK3342', 'PS49', '2025-11-25 11:00:00', '2025-11-25 12:30:00', 6.50, 5, 6, 2, 1, 0, 0);

INSERT INTO lpr_failure_logs (lpr_failure_id, lpr_id, lpr_failure_on_session_id, lpr_failure_datetime, lpr_failure_reason) VALUES
('LPRF1', 'LPR1', 'PST1', '2025-10-10 08:02:15', 'plate_not_detected'),
('LPRF2', 'LPR4', 'PST4', '2025-10-12 09:00:32', 'plate_no_entry_record'),
('LPRF3', 'LPR2', 'PST2', '2025-10-14 19:01:05', 'low_image_quality'),
('LPRF4', 'LPR2', 'PST2', '2025-10-15 18:03:48', 'low_image_quality'),
('LPRF5', 'LPR3', 'PST3', '2025-10-17 14:00:27', 'plate_not_detected'),
('LPRF6', 'LPR1', 'PST1', '2025-10-16 08:31:50', 'plate_number_blocked'),
('LPRF7', 'LPR6', 'PST6', '2025-10-13 07:16:11', 'plate_not_detected'),
('LPRF8', 'LPR8', 'PST8', '2025-10-18 12:01:09', 'plate_number_blocked'),
('LPRF9', 'LPR7', 'PST7', '2025-10-11 17:30:42', 'low_image_quality'),
('LPRF10', 'LPR2', 'PST2', '2025-10-19 09:01:17', 'low_image_quality'),
('LPRF11', 'LPR1', 'PST11', '2025-10-20 10:05:00', 'plate_not_detected'),
('LPRF12', 'LPR3',  'PST12', '2025-10-20 08:32:10', 'plate_not_detected'),
('LPRF13', 'LPR3',  'PST12', '2025-10-20 09:15:45', 'low_image_quality'),
('LPRF14', 'LPR4',  'PST13', '2025-10-21 09:05:20', 'plate_number_blocked'),
('LPRF15', 'LPR4',  'PST13', '2025-10-21 10:45:33', 'plate_not_detected'),
('LPRF16', 'LPR5',  'PST14', '2025-10-22 14:10:05', 'low_image_quality'),
('LPRF17', 'LPR6',  'PST15', '2025-10-23 11:35:42', 'plate_not_detected'),
('LPRF18', 'LPR6',  'PST15', '2025-10-23 12:20:18', 'plate_number_blocked');

INSERT INTO revenues (revenue_id, revenue_amount, revenue_type, parking_session_transaction_id, client_id, parkpoints_transaction_id) VALUES
('RV1', 8.00, 'parking_session', 'PST1', 'C1', NULL),
('RV2', 120.00, 'corporate_subscription', NULL, 'C2', NULL),
('RV3', 5.00, 'parkpoints_redemption', NULL, 'C3', 'PT1'),
('RV4', 50.00, 'penalties_for_unauthorized_parking_in_reserved_spot', 'PST2', 'C4', NULL),
('RV5', 9.00, 'parking_session', 'PST3', 'C5', NULL),
('RV6', 10.00, 'parking_session', 'PST4', 'C6', NULL),
('RV7', 60.00, 'corporate_subscription', NULL, 'C7', NULL),
('RV8', 4.50, 'parkpoints_redemption', NULL, 'C8', 'PT2'),
('RV9', 80.00, 'penalties_for_unauthorized_parking_in_reserved_spot', 'PST5', 'C9', NULL),
('RV10', 7.50, 'parking_session', 'PST6', 'C10', NULL);

INSERT INTO personnels (personnel_id, full_name, role, assigned_location_zone_id) VALUES
('P1', 'Ahmad Zulkifli', 'technician', 'ZN1'),
('P2', 'Siti Nurhaliza', 'attendant', 'ZN2'),
('P3', 'Lim Wei Jian', 'finance_officer', 'ZN3'),
('P4', 'Aisyah Rahman', 'zone_manager', 'ZN1'),
('P5', 'Raj Kumar', 'technician', 'ZN2'),
('P6', 'Nur Izzati', 'attendant', 'ZN4'),
('P7', 'Tan Boon Seng', 'finance_officer', 'ZN5'),
('P8', 'Mei Ling', 'zone_manager', 'ZN3'),
('P9', 'Faizal Hassan', 'technician', 'ZN4'),
('P10', 'Jessica Wong', 'attendant', 'ZN5');

INSERT INTO technicians (personnel_id, specialization) VALUES
('P1', 'Electrical Systems'),
('P5', 'Sensor Calibration'),
('P9', 'Network Infrastructure');

INSERT INTO attendants (personnel_id, shift_type) VALUES
('P2', 'Morning'),
('P6', 'Afternoon'),
('P10', 'Night');

INSERT INTO finance_officers (personnel_id, department) VALUES
('P3', 'Revenue Management'),
('P7', 'Financial Planning');

INSERT INTO zone_managers (personnel_id, years_of_experience) VALUES
('P4', 5.50),
('P8', 8.20);

INSERT INTO proactive_maintenance_alerts (proactive_maintenance_alert_id, sensor_id, sensor_failure_probability, predicted_sensor_failure_datetime, proactive_maintenance_alert_datetime) VALUES
('PA1', 'S1', 85, '2025-11-05 09:00:00', '2025-11-01 08:00:00'),
('PA2', 'S2', 73, '2025-11-06 10:15:00', '2025-11-02 09:30:00'),
('PA3', 'S3', 90, '2025-11-07 11:00:00', '2025-11-03 09:00:00'),
('PA4', 'S4', 65, '2025-11-07 13:30:00', '2025-11-03 10:00:00'),
('PA5', 'S5', 80, '2025-11-08 08:45:00', '2025-11-04 09:15:00'),
('PA6', 'S6', 78, '2025-11-09 10:00:00', '2025-11-04 11:00:00'),
('PA7', 'S7', 92, '2025-11-09 15:00:00', '2025-11-05 10:30:00'),
('PA8', 'S8', 68, '2025-11-10 09:30:00', '2025-11-05 11:15:00'),
('PA9', 'S9', 83, '2025-11-10 14:45:00', '2025-11-06 08:45:00'),
('PA10', 'S10', 95, '2025-11-11 16:00:00', '2025-11-06 09:30:00'),
('PA11', 'S18', 76, '2025-11-12 09:00:00', '2025-11-08 08:30:00'),
('PA12', 'S27', 81, '2025-11-13 11:00:00', '2025-11-09 09:15:00'),
('PA13', 'S37', 79, '2025-11-14 14:30:00', '2025-11-10 10:45:00'),
('PA14', 'S46', 88, '2025-11-15 16:00:00', '2025-11-11 11:20:00');

INSERT INTO maintenance_actions (maintenance_action_id, parking_spot_id, lpr_id, technician_id, maintenance_action_work_order_datetime, proactive_maintenance_alert_id, maintenance_action_status, maintenance_action_taken_datetime, description_of_work) VALUES
('MA1', 'PS1', 'LPR1', 'P1', '2025-11-01 08:30:00', 'PA1', 'pending', NULL, 'Sensor Replacement'),
('MA2', 'PS2', 'LPR2', 'P5', '2025-11-01 09:15:00', 'PA2', 'in_progress', '2025-11-01 10:00:00', 'Camera recalibration'),
('MA3', 'PS3', 'LPR1', 'P1', '2025-11-01 09:45:00', 'PA3', 'completed', '2025-11-01 11:00:00', 'Firmware update for LPR'),
('MA4', 'PS4', 'LPR4', 'P1', '2025-11-02 10:00:00', 'PA4', 'pending', NULL, 'Replace broken LED display'),
('MA5', 'PS5', 'LPR5', 'P9', '2025-11-02 10:30:00', 'PA5', 'completed', '2025-11-02 12:00:00', 'Gate arm motor service'),
('MA6', 'PS6', 'LPR3', 'P9', '2025-11-02 11:15:00', 'PA6', 'in_progress', '2025-11-02 12:00:00', 'Software patch installation'),
('MA7', 'PS7', 'LPR7', 'P5', '2025-11-02 13:00:00', 'PA7', 'cancelled', NULL, 'Scheduled maintenance cancelled due to weather'),
('MA8', 'PS8', 'LPR6', 'P9', '2025-11-03 08:00:00', 'PA8', 'completed', '2025-11-03 09:30:00', 'Replaced faulty wiring'),
('MA9', 'PS9', 'LPR8', 'P1', '2025-11-03 09:45:00', 'PA9', 'pending', NULL, 'Diagnostic test initiated'),
('MA10', 'PS10', 'LPR9', 'P5', '2025-11-03 10:15:00', 'PA10', 'completed', '2025-11-03 11:45:00', 'Calibration of entry sensors'),
('MA11', 'PS18', 'LPR10', 'P9', '2025-11-04 09:00:00', 'PA11', 'completed', '2025-11-04 10:30:00', 'Replaced corroded connector and tested EV charger'),
('MA12', 'PS27', 'LPR6', 'P5', '2025-11-05 14:00:00', 'PA12', 'completed', '2025-11-05 15:15:00', 'Fixed intermittent network drop on sensor'),
('MA13', 'PS37', 'LPR4', 'P1', '2025-11-06 09:30:00', 'PA13', 'completed', '2025-11-06 11:00:00', 'Cleaned housing, updated firmware, recalibrated sensor'),
('MA14', 'PS46', 'LPR11', 'P9', '2025-11-07 16:00:00', 'PA14', 'completed', '2025-11-07 17:20:00', 'Replaced faulty power module for LPR and sensor');

INSERT INTO alert_trigger_by_maintenance_logs (proactive_maintenance_alert_id, maintenance_action_id) VALUES
('PA1', 'MA1'),
('PA2', 'MA2'),
('PA3', 'MA3'),
('PA4', 'MA4'),
('PA5', 'MA5'),
('PA6', 'MA6'),
('PA7', 'MA7'),
('PA8', 'MA8'),
('PA9', 'MA9'),
('PA10', 'MA10'),
('PA11', 'MA11'),
('PA12', 'MA12'),
('PA13', 'MA13'),
('PA14', 'MA14');

INSERT INTO spot_inspections (spot_inspection_id, parking_spot_id, attendant_id, spot_inspection_result, spot_inspection_datetime) VALUES
('SI1', 'PS1', 'P2', 'pass', '2025-11-01 08:00:00'),
('SI2', 'PS2', 'P6', 'warning', '2025-11-01 09:15:00'),
('SI3', 'PS3', 'P10', 'requires_maintenance', '2025-11-01 10:00:00'),
('SI4', 'PS4', 'P2', 'pass', '2025-11-01 11:30:00'),
('SI5', 'PS5', 'P6', 'pass', '2025-11-02 08:45:00'),
('SI6', 'PS6', 'P10', 'warning', '2025-11-02 09:30:00'),
('SI7', 'PS7', 'P2', 'requires_maintenance', '2025-11-02 10:15:00'),
('SI8', 'PS8', 'P6', 'pass', '2025-11-03 08:00:00'),
('SI9', 'PS9', 'P10', 'warning', '2025-11-03 09:45:00'),
('SI10', 'PS10', 'P2', 'requires_maintenance', '2025-11-03 10:30:00');

INSERT INTO ai_models (ai_model_id, ai_model_name, ai_model_type) VALUES
('AI1', 'ParkGPT', 'chatbot'),
('AI2', 'VisionEye', 'image_recognition'),
('AI3', 'ParkPredict', 'predictive_analytics'),
('AI4', 'ParkGuard', 'anomaly_detection'),
('AI5', 'LPRPro', 'license_plate_recognition'),
('AI6', 'ZoneAI', 'parking_zone_optimizer'),
('AI7', 'FeeMaster', 'dynamic_pricing_model'),
('AI8', 'ParkAssist', 'voice_assistant'),
('AI9', 'SmartCount', 'vehicle_counting'),
('AI10', 'DataMind', 'data_analysis_engine');

INSERT INTO weathers (weather_id, weather_type, weather_APIs, location_zone_id, start_datetime, end_datetime) VALUES
('W1', 'Sunny', 'weatherapi.com', 'ZN1', '2025-11-01 07:00:00', '2025-11-01 19:00:00'),
('W2', 'Rain', 'weatherapi.com', 'ZN2', '2025-11-02 08:00:00', '2025-11-02 20:00:00'),
('W3', 'Cloudy', 'weatherapi.com', 'ZN3', '2025-11-03 06:30:00', '2025-11-03 18:30:00'),
('W4', 'Thunderstorm', 'weatherapi.com', 'ZN4', '2025-11-04 09:00:00', '2025-11-04 21:00:00'),
('W5', 'Drizzle', 'weatherapi.com', 'ZN5', '2025-11-05 07:15:00', '2025-11-05 19:15:00'),
('W6', 'Sunny', 'weatherapi.com', 'ZN1', '2025-11-06 06:45:00', '2025-11-06 18:45:00'),
('W7', 'Foggy', 'weatherapi.com', 'ZN2', '2025-11-07 05:30:00', '2025-11-07 17:30:00'),
('W8', 'Windy', 'weatherapi.com', 'ZN3', '2025-11-08 08:00:00', '2025-11-08 20:00:00'),
('W9', 'Rain', 'weatherapi.com', 'ZN4', '2025-11-09 07:30:00', '2025-11-09 19:30:00'),
('W10', 'Cloudy', 'weatherapi.com', 'ZN5', '2025-11-10 08:15:00', '2025-11-10 20:15:00');

INSERT INTO customer_support_chatbots (message_id, message_content, message_datetime, client_id) VALUES
('MS1', 'Hello! How can I assist you with parking today?', '2025-11-01 08:00:00', 'C1'),
('MS2', 'Your payment has been successfully processed.', '2025-11-01 08:05:00', 'C2'),
('MS3', 'The nearest parking zone is Zone 3.', '2025-11-01 08:10:00', 'C3'),
('MS4', 'Rain is expected later today, consider covered parking.', '2025-11-02 09:00:00', 'C4'),
('MS5', 'Your parking session will expire in 10 minutes.', '2025-11-02 09:15:00', 'C5'),
('MS6', 'Welcome back! Would you like to view your parking history?', '2025-11-03 10:00:00', 'C6'),
('MS7', 'System maintenance scheduled at midnight.', '2025-11-03 22:00:00', 'C7'),
('MS8', 'Your loyalty points balance is 120.', '2025-11-04 08:00:00', 'C8'),
('MS9', 'Camera #4 is under maintenance; please use another entry.', '2025-11-05 07:30:00', 'C9'),
('MS10', 'Thank you for contacting ParkGPT. Have a great day!', '2025-11-05 09:00:00', 'C10');

INSERT INTO ai_model_outputs (ai_model_output_id, ai_model_id, weather_id, output_content, output_type, output_datetime, predicted_demand_scores, optimal_pricing_indices) VALUES
('AIO1', 'AI1', 'W1', 'Predicted high parking demand in Zone A, 9–11AM.', 'demand_forecasting', '2025-11-01 07:00:00', 0.85, 1.10),
('AIO2', 'AI2', 'W2', 'Chatbot responded to 15 customer queries.', 'chatbot', '2025-11-01 08:00:00', NULL, NULL),
('AIO3', 'AI3', 'W3', 'Recommended optimal pricing: +5% for covered spots.', 'predictive_maintenance', '2025-11-01 09:00:00', 0.78, 1.05),
('AIO4', 'AI4', 'W4', 'Sensor 3 predicted failure risk 90%.', 'predictive_maintenance', '2025-11-01 10:00:00', NULL, NULL),
('AIO5', 'AI5', 'W5', 'Customer segmentation complete: 120 frequent users.', 'customer_segmentation', '2025-11-02 08:30:00', NULL, NULL),
('AIO6', 'AI6', 'W6', 'Rainy weather predicted — apply 10% discount.', 'demand_forecasting', '2025-11-02 09:45:00', 0.65, 0.90),
('AIO7', 'AI7', 'W7', 'License Plate Reader #4 needs maintenance check.', 'predictive_maintenance', '2025-11-02 10:00:00', NULL, NULL),
('AIO8', 'AI8', 'W8', 'Chatbot summary: 30% queries about payment issues.', 'chatbot', '2025-11-03 08:15:00', NULL, NULL),
('AIO9', 'AI9', 'W9', 'High occupancy predicted 95% for evening peak.', 'demand_forecasting', '2025-11-03 09:00:00', 0.95, 1.15),
('AIO10', 'AI10', 'W10', 'Predicted LPR downtime for sensor 6 in 2 days.', 'predictive_maintenance', '2025-11-03 10:30:00', NULL, NULL);

INSERT INTO sensor_predictive_maintenance_outputs (ai_model_output_id, sensor_id, sensor_predicted_maintenance_datetime) VALUES
('AIO3', 'S2', '2025-11-02 08:00:00'),
('AIO4', 'S3', '2025-11-05 12:00:00'),
('AIO10', 'S6', '2025-11-05 09:00:00');

INSERT INTO lpr_predictive_maintenance_outputs (ai_model_output_id, lpr_id, lpr_predicted_maintenance_datetime) VALUES
('AIO7', 'LPR4', '2025-11-04 11:00:00'),
('AIO10', 'LPR6', '2025-11-05 09:00:00');

INSERT INTO customer_segmentation_outputs (ai_model_output_id, client_id) VALUES
('AIO2', 'C1'),
('AIO5', 'C2'),
('AIO8', 'C3');

INSERT INTO demand_forecasting_outputs (ai_model_output_id, parking_spot_id) VALUES
('AIO1', 'PS1'),
('AIO3', 'PS2'),
('AIO6', 'PS4'),
('AIO9', 'PS5'),
('AIO10', 'PS6');

INSERT INTO chatbot_outputs (ai_model_output_id, message_id) VALUES
('AIO2', 'MS1'),
('AIO5', 'MS2'),
('AIO8', 'MS3');

INSERT INTO event_calendars (event_id, event_name, event_type, location_zone_id, start_datetime, end_datetime) VALUES
('E1', 'Deepavali Public Holiday', 'holiday', 'ZN1', '2025-11-01 00:00:00', '2025-11-01 23:59:59'),
('E2', 'Weekend Night Market', 'community', 'ZN2', '2025-11-01 18:00:00', '2025-11-01 23:00:00'),
('E3', 'Indie Band Live', 'concert', 'ZN3', '2025-11-02 19:30:00', '2025-11-02 22:00:00'),
('E4', 'Football Match Viewing', 'sports', 'ZN4', '2025-11-03 20:00:00', '2025-11-03 23:00:00'),
('E5', 'Mall Mega Sale', 'promotion', 'ZN5', '2025-11-04 10:00:00', '2025-11-04 22:00:00'),
('E6', 'Rain Advisory', 'weather', 'ZN1', '2025-11-05 08:00:00', '2025-11-05 20:00:00'),
('E7', 'Food Truck Festival', 'festival', 'ZN2', '2025-11-06 11:00:00', '2025-11-06 21:00:00'),
('E8', 'University Convocation', 'ceremony', 'ZN3', '2025-11-07 08:00:00', '2025-11-07 14:00:00'),
('E9', 'New Year Countdown Rehearsal', 'rehearsal', 'ZN4', '2025-11-08 18:00:00', '2025-11-08 21:00:00'),
('E10', 'Charity Run', 'sports', 'ZN5', '2025-11-09 06:30:00', '2025-11-09 11:00:00');

INSERT INTO multiple_event_sources (ai_model_output_id, event_id) VALUES
('AIO1', 'E1'),
('AIO2', 'E2'),
('AIO3', 'E3'),
('AIO4', 'E4'),
('AIO5', 'E5'),
('AIO6', 'E6'),
('AIO7', 'E7'),
('AIO8', 'E8'),
('AIO9', 'E9'),
('AIO10', 'E10');

INSERT INTO sensor_sources (ai_model_output_id, sensor_id) VALUES
('AIO1', 'S1'),
('AIO1', 'S2'),
('AIO2', 'S3'),
('AIO3', 'S4'),
('AIO3', 'S5'),
('AIO4', 'S6'),
('AIO5', 'S7'),
('AIO6', 'S8'),
('AIO7', 'S9'),
('AIO8', 'S10');

INSERT INTO lpr_sources (ai_model_output_id, lpr_id) VALUES
('AIO1', 'LPR1'),
('AIO2', 'LPR2'),
('AIO3', 'LPR3'),
('AIO3', 'LPR4'),
('AIO4', 'LPR5'),
('AIO5', 'LPR6'),
('AIO6', 'LPR7'),
('AIO7', 'LPR8'),
('AIO8', 'LPR9'),
('AIO9', 'LPR10');

INSERT INTO client_sources (ai_model_output_id, client_id) VALUES
('AIO1', 'C1'),
('AIO2', 'C2'),
('AIO2', 'C3'),
('AIO3', 'C4'),
('AIO4', 'C5'),
('AIO5', 'C6'),
('AIO6', 'C7'),
('AIO7', 'C8'),
('AIO8', 'C9'),
('AIO9', 'C10');

INSERT INTO parking_spot_sources (ai_model_output_id, parking_spot_id) VALUES
('AIO1', 'PS1'),
('AIO1', 'PS2'),
('AIO2', 'PS3'),
('AIO3', 'PS4'),
('AIO3', 'PS5'),
('AIO4', 'PS6'),
('AIO5', 'PS7'),
('AIO6', 'PS8'),
('AIO7', 'PS9'),
('AIO8', 'PS10');

------------------------------------------
-- Part C
------------------------------------------

-- Q5
SELECT c.full_name, 
       v.license_plate_number
FROM clients c
JOIN vehicles v ON c.client_id = v.client_id
WHERE c.business_relationship_type = 'corporate_fleet_account'
AND v.is_ev = TRUE
AND c.brand_affiliation = 'pro';


-- Q6
SELECT SUM(pst.base_charge) AS total_basecharge_revenue
FROM parking_sessions pst
JOIN parking_spots ps ON ps.parking_spot_id =  pst.parking_spot_id 
JOIN location_zones lz ON lz.location_zone_id = ps.location_zone_id
WHERE lz.location_zone_name = 'bukit_bintang';


-- Q7
SELECT ps.parking_spot_id, 
       lz.location_zone_name, 
       MAX(ma.maintenance_action_taken_datetime)
FROM parking_spots ps
JOIN sensors s ON ps.sensor_id = s.sensor_id
JOIN location_zones lz ON ps.location_zone_id = lz.location_zone_id
LEFT JOIN maintenance_actions ma ON ps.parking_spot_id = ma.parking_spot_id
WHERE s.sensor_status = 'offline'
GROUP BY ps.parking_spot_id, lz.location_zone_name;


-- Q8
SELECT c.client_id, 
       ROUND((
           TIMESTAMPDIFF(MINUTE, pst.start_datetime, pst.end_datetime)/60.0 
           * ps.standard_hourly_rate 
           * (1 + pst.dynamic_surcharge_percent/100)) 
           * (1 - pst.loyalty_discount_percent/100), 2) AS final_charge
FROM parking_sessions pst
JOIN vehicles v ON v.license_plate_number = pst.license_plate_number
JOIN clients c ON v.client_id = c.client_id
JOIN loyalty_tiers lt ON lt.loyalty_tier_id = c.loyalty_tier_id
JOIN parking_spots ps ON pst.parking_spot_id = ps.parking_spot_id
WHERE ps.standard_hourly_rate = 5
AND pst.dynamic_surcharge_percent = 20
AND lt.tier_name = 'gold'
AND TIMESTAMPDIFF(MINUTE, pst.start_datetime, pst.end_datetime) >= 180;


-- Q9
SELECT lz.location_zone_name, 
       COUNT(DISTINCT pst.parking_session_transaction_id) AS transactions_with_lpr_failures
FROM lpr_failure_logs lprfl
JOIN parking_sessions pst ON pst.parking_session_transaction_id = lprfl.lpr_failure_on_session_id
JOIN parking_spots ps ON ps.parking_spot_id = pst.parking_spot_id
JOIN location_zones lz ON lz.location_zone_id = ps.location_zone_id
GROUP BY lz.location_zone_name;


-- Q10
SELECT c.client_id, 
       c.parkpoints_balance, 
       c.preferred_payment_method, 
       lt.tier_name, 
       c.brand_affiliation
FROM clients c
JOIN loyalty_tiers lt ON c.loyalty_tier_id = lt.loyalty_tier_id
WHERE c.preferred_payment_method = 'blockchain_token'
ORDER BY c.parkpoints_balance DESC
LIMIT 10;

------------------------------------------
-- Part D
------------------------------------------

-- Report 1: Highest Zone Demand Report
WITH session_count AS (
    SELECT ps.location_zone_id, 
    COUNT(pst.parking_session_transaction_id) AS demand
    FROM parking_spots ps
    LEFT JOIN parking_sessions pst ON pst.parking_spot_id = ps.parking_spot_id
    GROUP BY ps.location_zone_id
)
SELECT lz.location_zone_name, sc.demand
FROM location_zones lz
LEFT JOIN session_count sc ON sc.location_zone_id = lz.location_zone_id
ORDER BY sc.demand DESC;


-- Report 2: Monthly Parking Revenue by Zone
DROP VIEW IF EXISTS vw_session_revenue; -- (If error exists, drop and re-run)
CREATE VIEW vw_session_revenue AS
SELECT pst.parking_spot_id,
       pst.start_datetime,
       (pst.base_charge 
        * (1 + pst.dynamic_surcharge_percent/100)
        * (1 + pst.local_taxes_percent/100)
        * (1 - pst.total_discount_percent/100)) AS revenue
FROM parking_sessions pst;
SELECT lz.location_zone_name,
       MONTH(vr.start_datetime) AS month,
       ROUND(SUM(vr.revenue), 2) AS monthly_revenue
FROM vw_session_revenue vr
JOIN parking_spots ps ON ps.parking_spot_id = vr.parking_spot_id
JOIN location_zones lz ON ps.location_zone_id = lz.location_zone_id
GROUP BY lz.location_zone_name, month
ORDER BY monthly_revenue DESC;


-- Report 3: Revenue by Parking Type
WITH type_revenue AS (
    SELECT pst.parking_spot_id,
           (pst.base_charge 
            * (1 + pst.dynamic_surcharge_percent/100)
            * (1 + pst.local_taxes_percent/100)
            * (1 - pst.total_discount_percent/100)) AS revenue
    FROM parking_sessions pst
)
SELECT ps.space_type AS Parking_Type,
       ROUND(SUM(tr.revenue), 2) AS Total_Revenue
FROM parking_spots ps
RIGHT JOIN type_revenue tr ON tr.parking_spot_id = ps.parking_spot_id
WHERE ps.space_type IS NOT NULL
GROUP BY ps.space_type;


-- Report 4: Average parking duration for brand affiliation pattern
WITH brand_expanded AS (
    SELECT client_id, 'pro' AS brand_category
    FROM clients WHERE brand_affiliation = 'pro'
    UNION ALL
    SELECT client_id, 'tourist' AS brand_category
    FROM clients WHERE brand_affiliation = 'tourist'
    UNION ALL
    SELECT client_id, 'pro' AS brand_category
    FROM clients WHERE brand_affiliation = 'both'
    UNION ALL
    SELECT client_id, 'tourist' AS brand_category
    FROM clients WHERE brand_affiliation = 'both'
    UNION ALL
    SELECT client_id, 'no_brand' AS brand_category
    FROM clients WHERE brand_affiliation IS NULL
)

SELECT lz.location_zone_name,
       be.brand_category,
       COUNT(pst.parking_session_transaction_id) AS transaction_count,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, pst.start_datetime, pst.end_datetime)/60.0), 2) AS average_parking_duration_hours
FROM location_zones lz
JOIN parking_spots ps ON ps.location_zone_id = lz.location_zone_id
JOIN parking_sessions pst ON pst.parking_spot_id = ps.parking_spot_id
JOIN vehicles v ON v.license_plate_number = pst.license_plate_number
JOIN brand_expanded be ON be.client_id = v.client_id
GROUP BY lz.location_zone_name, be.brand_category
ORDER BY lz.location_zone_name, be.brand_category;


-- Report 5: Revenue by loyalty tier
SELECT lt.tier_name,
	ROUND(
		SUM(
        (pst.base_charge 
		* (1 + pst.dynamic_surcharge_percent/100) 
		* (1 + local_taxes_percent/100))
		* (1 - total_discount_percent/100)
		),2
	)AS Total_Revenue
FROM parking_sessions pst
JOIN vehicles v ON v.license_plate_number = pst.license_plate_number
JOIN clients c ON c.client_id = v.client_id
JOIN loyalty_tiers lt ON lt.loyalty_tier_id = c.loyalty_tier_id
GROUP BY lt.tier_name

require('dotenv').config();
const express = require("express");
const mysql = require("mysql2");
const bcrypt = require("bcryptjs");
const bodyParser = require("body-parser");
const cors = require("cors");
const app = express();


const port = process.env.SERVER_PORT;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// MySQL Connection
function handleDisconnect() {
  const db = mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT,
  });

  // Connect to MySQL
  db.connect((err) => {
    if (err) {
      console.error("Error connecting to MySQL:", err);
      setTimeout(handleDisconnect, 5000); // Retry after 5 seconds
    } else {
      console.log("Connected to MySQL");
    }
  });

  // Handle connection errors
  db.on("error", (err) => {
    console.error("MySQL error:", err);
    if (err.code === "PROTOCOL_CONNECTION_LOST") {
      console.log("Reconnecting to MySQL...");
      handleDisconnect(); // Reconnect on connection loss
    } else {
      throw err;
    }
  });

  return db;
}

// Initialize database connection
const db = handleDisconnect();

// Login Endpoint
app.post("/login", (req, res) => {
  const { email, password } = req.body;

  const sql =
    "SELECT email_address, hashed_password FROM user_credentials WHERE email_address = ?";
  db.query(sql, [email], (err, results) => {
    if (err) {
      return res
        .status(500)
        .json({ status: "error", message: "Database query error" });
    }

    if (results.length > 0) {
      const hashedPassword = results[0].hashed_password;

      bcrypt.compare(password, hashedPassword, (err, isMatch) => {
        if (err) {
          return res
            .status(500)
            .json({ status: "error", message: "Error comparing passwords" });
        }

        if (isMatch) {
          return res
            .status(200)
            .json({ status: "success", message: "Login successful" });
        } else {
          return res
            .status(401)
            .json({
              status: "error",
              message:
                "The password you entered is incorrect. Please try again.",
            });
        }
      });
    } else {
      return res
        .status(404)
        .json({ status: "error", message: "User not found" });
    }
  });
});
// Locations Endpoint
app.get("/locations", (req, res) => {
  const sql =
    "SELECT DISTINCT factory_location FROM factory_data ORDER BY factory_location";
  

  db.query(sql, (err, results) => {
    if (err) {
      console.error("Database error:", err);
      return res.status(500).json({
        status: "error",
        message: "Error fetching locations",
        error: err.message,
      });
    }

    const locations = results
      .map((row) => row.factory_location)
      .filter((location) => location != null && location.trim() !== "");

    console.log("Processed locations:", locations); // Debug log

    return res.status(200).json({
      status: "success",
      locations: locations,
    });
  });
});

// Shop Floors Endpoint
app.get("/shopfloors/:location", (req, res) => {
  const location = req.params.location;
  console.log("Received request for shop floors at location:", location); // Debug log

  const sql = `
        SELECT DISTINCT s.shop_floor_name 
        FROM shop_floor_details s
        JOIN factory_data f ON s.factory_id = f.factory_id
        WHERE f.factory_location = ? 
        ORDER BY s.shop_floor_name
    `;

  db.query(sql, [location], (err, results) => {
    if (err) {
      console.error("Error fetching shop floors:", err);
      return res.status(500).json({
        status: "error",
        message: "Error fetching shop floors",
        error: err.message,
      });
    }

    const shopFloors = results
      .map((row) => row.shop_floor_name)
      .filter((floor) => floor != null);
    console.log("Fetched shop floors for location:", location, shopFloors); // Debug log

    return res.status(200).json({
      status: "success",
      shopFloors: shopFloors,
    });
  });
});

  // Lines endpoint with machine status
  app.get("/lines/:location/:shopFloor", async (req, res) => {
    
    try {
      const { location, shopFloor } = req.params;
  
      const query = `
        WITH latest_edge_minder AS (
            SELECT
                ip_address,
                edge_minder_connection_status,
                timestamp,
                ROW_NUMBER() OVER (PARTITION BY ip_address ORDER BY timestamp DESC) AS rn
            FROM edge_minder_connection_logs
        ),
        latest_hmi_minder AS (
            SELECT
                ip_address,
                hmi_minder_connection_status,
                connection_timestamp,
                ROW_NUMBER() OVER (PARTITION BY ip_address ORDER BY connection_timestamp DESC) AS rn
            FROM hmi_minder_connection_logs
        ),
        recent_machine_parameters AS (
            SELECT
                ip_address,
                machine_mode,
                pump_status,
                heater_status,
                timestamp,
                ROW_NUMBER() OVER (PARTITION BY ip_address ORDER BY timestamp DESC) AS rn
            FROM machine_parameters
            WHERE timestamp >= NOW() - INTERVAL 120 SECOND
        )
        SELECT
            md.production_line_id,
            md.machine_id,
            md.machine_name,
            md.ip_address,
            CASE
                WHEN em.edge_minder_connection_status = 0 OR hm.hmi_minder_connection_status = 0 THEN 'grey'
                WHEN em.edge_minder_connection_status = 1 AND hm.hmi_minder_connection_status = 1 THEN
                    CASE
                        WHEN mp.pump_status = 0 OR mp.heater_status = 0 THEN 'red'
                        WHEN mp.machine_mode = 3 THEN 'yellow'
                        WHEN mp.machine_mode = 4 THEN 'green'
                        ELSE 'grey'
                    END
                ELSE 'grey'
            END AS color_code,
            CASE
                WHEN em.edge_minder_connection_status = 0 THEN 'Not available'
                WHEN hm.hmi_minder_connection_status = 0 THEN 'Not available'
                WHEN mp.ip_address IS NULL THEN 'Not available'
                WHEN mp.machine_mode IN (3, 4) AND mp.pump_status = 1 AND mp.heater_status = 1 THEN 'Running'
                ELSE 'Not running'
            END AS machine_status
        FROM factory_data f
        JOIN shop_floor_details sf ON f.factory_id = sf.factory_id
        JOIN machine_details md ON f.factory_id = md.factory_id AND sf.shop_floor_id = md.shop_floor_id
        LEFT JOIN latest_edge_minder em ON md.ip_address = em.ip_address AND em.rn = 1
        LEFT JOIN latest_hmi_minder hm ON md.ip_address = hm.ip_address AND hm.rn = 1
        LEFT JOIN recent_machine_parameters mp ON md.ip_address = mp.ip_address AND mp.rn = 1
        WHERE f.factory_location = ? AND sf.shop_floor_name = ?
        ORDER BY md.production_line_id, md.machine_id`;

      const [results] = await db.promise().query(query, [location, shopFloor]);

      const productionLines = results.reduce((acc, machine) => {
        const lineId = machine.production_line_id;
        if (!acc[lineId]) acc[lineId] = [];

        acc[lineId].push({
          machineId: machine.machine_id,
          machineName: machine.machine_name,
          ipAddress: machine.ip_address,
          colorCode: machine.color_code,
          machineStatus: machine.machine_status
        });

        return acc;
      }, {});

      return res.status(200).json({
        status: "success",
        productionLines
      });

    } catch (error) {
      console.error("Error in lines endpoint:", error);
      return res.status(500).json({
        status: "error", 
        message: "Internal server error"
      });
    }
});


 // overall Plant OEE Production with machine status
 app.get("/overallPlantOEE/:location/:shopFloor", async (req, res) => {

  try {
    const { location, shopFloor } = req.params;
    const { fromTime, toTime } = req.query;
  
    if (!fromTime || !toTime) {
	return res.status(400).json({
		status: "error",
		message: "start time and endtime are required",
	});
     }
	console.log("received params:", { location, shopFloor, fromTime,toTime });

    const query = `SELECT md.ip_address, md.machine_name,
        mpmh.from_time, 
        mpmh.to_time, 
        mpmh.reject_parts_count, 
        mpmh.productivity_percentage, 
        mpmh.quality_percentage, 
        mpmh.utilization_percentage, 
        mpmh.overall_equipment_effectiveness_percentage,
	mpmh.energy_consumption, 
        mpmh.good_parts_count
    FROM machine_details md 
    JOIN machine_performance_metrics_hourly mpmh
      ON md.ip_address = mpmh.ip_address
    JOIN factory_data fd
	ON md.factory_id = fd.factory_id
    JOIN shop_floor_details sf
	ON md.shop_floor_id = sf.shop_floor_id
    WHERE fd.factory_location = ?
     AND sf.shop_floor_name = ?
     AND mpmh.from_time >= ?
     AND mpmh.to_time <= ?
    ORDER BY mpmh.from_time DESC`;

    const [results] = await db.promise().query(query, [location, shopFloor, fromTime, toTime]);
    console.log(results);
    return res.status(200).json({
      status: "success",
      plantMetrics: results,
      debug: {
        timeRange: `${fromTime} to ${toTime}`,
        Locationplace: location,
        shopFloorID: shopFloor,
        recordCount: results.length,
      },
    });

  } catch (error) {
    console.error("Error in fetching OEE OverallPlant data:", error);
    return res.status(500).json({
      status: "error", 
      message: "Internal server error"
    });
  }
});


app.get("/avgPlantOEE/:location/:shopFloor", async (req, res) => {
  try {
    const { location, shopFloor } = req.params;
    let { fromTime, toTime  } = req.query;

    // Validate Inputs
    if (!fromTime || !toTime) {
      return res.status(400).json({
        status: "error",
        message: "Start Time and End Time are required",
      });
    }

    console.log("Received Params:", { location, shopFloor, fromTime, toTime });

    // SQL Query
    const query = `
      SELECT 
    AVG(mpmh.productivity_percentage) AS avg_productivity,
    AVG(mpmh.quality_percentage) AS avg_quality,
    AVG(mpmh.utilization_percentage) AS avg_utilization,
    AVG(mpmh.overall_equipment_effectiveness_percentage) AS avg_oee
FROM machine_details md
JOIN machine_performance_metrics_hourly mpmh 
    ON md.ip_address = mpmh.ip_address
JOIN meipaari_cloud.factory_data fd 
    ON md.factory_id = fd.factory_id
JOIN meipaari_cloud.shop_floor_details sf 
    ON md.shop_floor_id = sf.shop_floor_id
WHERE fd.factory_location = ? 
  AND sf.shop_floor_name = ?
  AND mpmh.from_time >= ? 
  AND mpmh.to_time <= ?
    `;

    // Execute Query
    const [results] = await db.promise().query(query, [location, shopFloor, fromTime, toTime]);

    console.log("Query Results:", results);

    return res.status(200).json({
      status: "success",
      avgplantMetrics: results,
      debug: {
        timeRange: `${fromTime} to ${toTime}`,
        location,
        shopFloor,
        recordCount: results.length,
      },
    });

  } catch (error) {
    console.error("Error in fetching OEE data:", error);
    return res.status(500).json({
      status: "error", 
      message: "Internal server error",
      details: error.message,
    });
  }
});


//machine details endpoint
app.get("/machine-metrics/:ipAddress", async (req, res) => {
  try {
    let ipAddress = req.params.ipAddress;

    // Convert only if IP is in dotted format
    if (ipAddress.includes('.')) {
      ipAddress = ipAddress.replace(/\./g, '_');
    }

    const { fromTime, toTime } = req.query;

    console.log('Received times:', { fromTime, toTime });

    if (!fromTime || !toTime) {
      return res.status(400).json({
        status: "error",
        message: "Missing fromTime or toTime parameters",
      });
    }

    // Parse the dates but preserve the time as-is without timezone conversion
    const parseDateTime = (dateTimeStr) => {
      const [date, time] = dateTimeStr.split(' ');
      const [hour] = time.split(':');
      return `${date} ${hour}:00:00`;
    };

    const formattedFromTime = parseDateTime(fromTime);
    const formattedToTime = parseDateTime(toTime);

    console.log('Using times:', {
      formattedFromTime,
      formattedToTime
    });

    // SQL Query
    const query = `
       SELECT
          COUNT(*) AS TotalRecords,
          AVG(
              CASE
                  WHEN productivity_percentage > 0 THEN productivity_percentage
                  ELSE NULL
              END
          ) AS AvgProductivity, -- Excludes zeros
         
          (SUM(good_parts_count) * 100.0 / NULLIF(SUM(actual_part_production), 0)) AS QualityPercentage,

          AVG(
              CASE
                  WHEN utilization_percentage > 0 THEN utilization_percentage
                  WHEN utilization_percentage = 0 AND EXISTS (
                      SELECT 1
                      FROM downtime_logs dt
                      WHERE dt.from_time = a.from_time
                          AND dt.to_time = a.to_time
                          AND dt.downtime_category = 'unplanned'
                          AND NOT EXISTS (
                              SELECT 1
                              FROM downtime_logs dt2
                              WHERE dt2.from_time = a.from_time
                                  AND dt2.to_time = a.to_time
                                  AND dt2.downtime_category != 'unplanned'
                                  AND dt2.downtime_approval = 3
                          )
                  ) THEN utilization_percentage
                  ELSE NULL
              END
          ) AS AvgUtilization,
          SUM(energy_consumption) AS TotalEnergyVal,
          ROUND(
              (
                  AVG(
                      CASE
                          WHEN utilization_percentage > 0 THEN utilization_percentage
                          ELSE NULL
                      END
                  ) * (SUM(good_parts_count) * 100.0 / NULLIF(SUM(actual_part_production), 0))
                  * AVG(
                      CASE
                          WHEN productivity_percentage > 0 THEN productivity_percentage
                          ELSE NULL
                      END
                  ) / 10000
              ), 2
          ) AS OEE_percentage
      FROM machine_performance_metrics_hourly AS a
      WHERE from_time >= ? AND to_time <= ? AND ip_address = ? `;

    console.log("Executing SQL Query...");

    // Execute Query
    const [results] = await db.promise().query(query, [formattedFromTime, formattedToTime, ipAddress]);

    console.log(`Found ${results.length} records`);

    return res.status(200).json({
      status: "success",
      metrics: results,
      debug: {
        timeRange: `${formattedFromTime} to ${formattedToTime}`,
        ipAddress,
        recordCount: results.length,
      },
    });

  } catch (error) {
    console.error("Error fetching machine metrics:", error);
    return res.status(500).json({
      status: "error",
      message: "Error fetching machine metrics",
      error: error.message,
    });
  }
});

app.get("/machine-metrics-table/:ipAddress", async (req, res) => {
  try {
    let ipAddress = req.params.ipAddress;

    // Convert only if IP is in dotted format
    if (ipAddress.includes('.')) {
      ipAddress = ipAddress.replace(/\./g, '_');
    }

    const { fromTime, toTime } = req.query;

    console.log('Received times:', { fromTime, toTime });

    if (!fromTime || !toTime) {
      return res.status(400).json({
        status: "error",
        message: "Missing fromTime or toTime parameters",
      });
    }

    // Parse the dates but preserve the time as-is without timezone conversion
    const parseDateTime = (dateTimeStr) => {
      const [date, time] = dateTimeStr.split(' ');
      const [hour] = time.split(':');
      return `${date} ${hour}:00:00`;
    };

    const formattedFromTime = parseDateTime(fromTime);
    const formattedToTime = parseDateTime(toTime);

    console.log('Using times:', {
      formattedFromTime,
      formattedToTime
    });

    // Calculate time difference using original dates to avoid timezone issues
    const fromDate = new Date(fromTime.replace(' ', 'T'));
    const toDate = new Date(toTime.replace(' ', 'T'));
    const diffHours = Math.abs(toDate - fromDate) / (1000 * 60 * 60);
    
    const tableToQuery = diffHours <= 24 ? 'machine_performance_metrics_hourly' : 'machine_performance_metrics_daily';
  

    
    const query = `
      SELECT 
        from_time,
        to_time,
        productivity_percentage,
        quality_percentage,
        utilization_percentage,
        overall_equipment_effectiveness_percentage
      FROM ${tableToQuery}
      WHERE ip_address = ? 
        AND from_time >= ?
        AND from_time <= ?
      ORDER BY from_time ASC
      `;
    

    console.log('Final query parameters:', {
      ipAddress: ipAddress,
      timeRange: `${formattedFromTime} to ${formattedToTime}`,
    });

    const [results] = await db.promise().query(
      query, 
      [ipAddress, formattedFromTime, formattedToTime]
    );

    console.log(`Found ${results.length} records`);

    return res.status(200).json({
      status: "success",
      metrics: results,
      debug: {
        timeRange: `${formattedFromTime} to ${formattedToTime}`,
        ipAddress: ipAddress,
        recordCount: results.length,
      },
    });

  } catch (error) {
    console.error("Error fetching machine metrics:", error);
    return res.status(500).json({
      status: "error",
      message: "Error fetching machine metrics",
      error: error.message,
    });
  }
});

app.get("/machine-metrics-moldwise/:ipAddress", async (req, res) => {
  try {
    let ipAddress = req.params.ipAddress;

    // Convert only if IP is in dotted format
    if (ipAddress.includes('.')) {
      ipAddress = ipAddress.replace(/\./g, '_');
    }

    const { fromTime, toTime } = req.query;

    console.log('Received times:', { fromTime, toTime });

    if (!fromTime || !toTime) {
      return res.status(400).json({
        status: "error",
        message: "Missing fromTime or toTime parameters",
      });
    }

    // Parse the dates but preserve the time as-is without timezone conversion
    const parseDateTime = (dateTimeStr) => {
      const [date, time] = dateTimeStr.split(' ');
      const [hour] = time.split(':');
      return `${date} ${hour}:00:00`;
    };

    const formattedFromTime = parseDateTime(fromTime);
    const formattedToTime = parseDateTime(toTime);

    console.log('Using times:', {
      formattedFromTime,
      formattedToTime
    });

    const query = `WITH mold_data AS (
      SELECT 
          mp.mold_id,
          mp.timestamp,
          mp.cavity_count,
          mp.actual_good_parts,
          mp.actual_rejected_parts,
          mp.actual_good_shots,
          mp.actual_total_shots,
          mp.shot_weight,
          mp.material_name,
          mp.energy_consumption,
          LAG(mp.actual_good_parts) OVER (PARTITION BY mp.mold_id ORDER BY mp.timestamp) AS prev_good_parts,
          LAG(mp.actual_rejected_parts) OVER (PARTITION BY mp.mold_id ORDER BY mp.timestamp) AS prev_rejected_parts,
          LAG(mp.actual_good_shots) OVER (PARTITION BY mp.mold_id ORDER BY mp.timestamp) AS prev_good_shots,
          LAG(mp.actual_total_shots) OVER (PARTITION BY mp.mold_id ORDER BY mp.timestamp) AS prev_total_shots,
          LAG(mp.energy_consumption) OVER (PARTITION BY mp.mold_id ORDER BY mp.timestamp) AS prev_energy_consumption
      FROM machine_parameters mp
      WHERE mp.ip_address = ?  
          AND mp.timestamp BETWEEN ? AND ?  
  )
  SELECT 
      mold_id,
      material_name,
      shot_weight,  
      cavity_count,
      SUM(CASE 
          WHEN actual_good_parts >= COALESCE(prev_good_parts, 0) THEN actual_good_parts - prev_good_parts 
          ELSE actual_good_parts 
      END) AS good_parts_difference,
      SUM(CASE 
          WHEN actual_rejected_parts >= COALESCE(prev_rejected_parts, 0) THEN actual_rejected_parts - prev_rejected_parts 
          ELSE actual_rejected_parts 
      END) AS rejected_parts_difference,
      SUM(CASE 
          WHEN actual_good_shots >= COALESCE(prev_good_shots, 0) THEN actual_good_shots - prev_good_shots 
          ELSE actual_good_shots 
      END) AS good_shots_difference,
      SUM(CASE 
          WHEN actual_total_shots >= COALESCE(prev_total_shots, 0) THEN actual_total_shots - prev_total_shots 
          ELSE actual_total_shots 
      END) AS total_shots_difference,
      SUM((CASE 
          WHEN actual_total_shots >= COALESCE(prev_total_shots, 0) THEN actual_total_shots - prev_total_shots 
          ELSE actual_total_shots 
      END) * cavity_count) AS total_parts,
      SUM((CASE 
          WHEN actual_total_shots >= COALESCE(prev_total_shots, 0) THEN actual_total_shots - prev_total_shots 
          ELSE actual_total_shots 
      END) * shot_weight) AS material_consumption,
      SUM(CASE 
          WHEN energy_consumption >= prev_energy_consumption THEN energy_consumption - prev_energy_consumption 
          ELSE energy_consumption 
      END) AS energy_consumption  
  FROM mold_data
  WHERE prev_good_parts IS NOT NULL  
  GROUP BY mold_id, cavity_count, material_name, shot_weight`;

    console.log('Final query parameters:', {
      ipAddress: ipAddress,
      timeRange: `${formattedFromTime} to ${formattedToTime}`,
    });

    const [results] = await db.promise().query(
      query, 
      [ipAddress, formattedFromTime, formattedToTime]
    );

    console.log(`Found ${results.length} records`);

    return res.status(200).json({
      status: "success",
      metrics: results,
      debug: {
        timeRange: `${formattedFromTime} to ${formattedToTime}`,
        ipAddress: ipAddress,
        recordCount: results.length,
      },
    });

  } catch (error) {
    console.error("Error fetching machine metrics:", error);
    return res.status(500).json({
      status: "error",
      message: "Error fetching machine metrics",
      error: error.message,
    });
  }
});

// Start the server
app.listen( process.env.SERVER_PORT, '0.0.0.0', () => {
  console.log("Server running on 0.0.0.0:3000");
});

app.use((req, res) => {
  console.log(`Unhandled route: ${req.method} ${req.url}`);
  res.status(404).send(`Cannot ${req.method} ${req.url}`);
});





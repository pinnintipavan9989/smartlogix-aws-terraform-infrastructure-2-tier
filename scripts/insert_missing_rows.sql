USE smartlogix;
CREATE TABLE IF NOT EXISTS Shipments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  shipment_id VARCHAR(64),
  origin VARCHAR(128),
  destination VARCHAR(128),
  status VARCHAR(64),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS StatusHistory (
  id INT AUTO_INCREMENT PRIMARY KEY,
  shipment_id VARCHAR(64),
  status VARCHAR(64),
  changed_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Sample shipments
INSERT INTO Shipments (shipment_id, origin, destination, status) VALUES
('SHP-1001','Delhi','Mumbai','In Transit'),
('SHP-1002','Bengaluru','Hyderabad','Delivered'),
('SHP-1003','Chennai','Kolkata','Pending');

-- Sample status history
INSERT INTO StatusHistory (shipment_id, status) VALUES
('SHP-1001','Picked Up'),
('SHP-1001','In Transit');

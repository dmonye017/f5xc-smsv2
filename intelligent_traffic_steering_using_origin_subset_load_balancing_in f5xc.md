# How to configure Intelligent Traffic Steering (using Origin Subset Load Balancing) on a HTTP Load Balancer in F5 Distributed Cloud

## Typical Scenario
Suppose you have multiple origin servers in different regions (say Japan, London and New York) and you want to configure your HTTP Load Balancer to be able to intelligently steer traffic to these origin servers based on geolocation for example,
the answer lies in enabling **Origin Subset Load Balancing**.

**Origin Subset Load Balancing** in F5XC is a feature that lets you partition the endpoints within a single origin pool into logical groups using key-value pairs, and then define rules on the HTTP LB that steer incoming traffic to a specific
group based on characteristics of the request source - such as the client's country, ASN, Regional Edge, IP address or client label. This is accomplished by **tagging** each origin server with a label (e.g. region: us-east), enabling subset 
load balancing on the origin pool by specifying which label key to partition on, and then configuring subset rules on the load balancer that say "If the request matches condition X, route it only to endpoints carrying label value Y". 
Traffic that does not match any rule falls back either to any available endpoint or is denied, depending on your fallback policy. 

Simply put, it's conditional endpoint selection within a pool, driven by request metadata matched against endpoint labels.

## Prerequisites
- An F5 Distributed Cloud tenant with permissions to create and manage HTTP Load Balancers
- A geolocation key label for the origin servers (e.g., Japan, US, Europe) to enable geolocation-based routing
- Three origin servers (e.g., web servers) hosting your application in three different regions.

### Step 1: Create a Geolocation Key Label for each origin server
1. Log into your F5 Distributed Cloud tenant.
2. In the F5 Distributed Cloud Console, navigate to the **Shared Configuration** > **Labels** > **Known Keys**.
3. Click **Add Known Key** and specify the following details: 
    - Label Key: **arc-geolocation**
    - Label Value 1: **Japan**
    - Label Value 2: **London**
    - Label Value 3: **Virginia**
4. Click **Add Key** to create the geolocation key label.

### Step 2: Create an Origin Pool for the HTTP Load Balancer
1. In the F5 Distributed Cloud Console, navigate to **Multi-Cloud App Connect** > **Load Balancers** > **Origin Pools**.
2. Select **Add Origin Pool** and specify the following details:
   - Name: **arcadia-gs-op1**
   - In the **Origin Servers** section, click **Add Origin Server** to add each of the three origin servers with their respective public IP addresses and geolocation labels.
   - Specify the following details for each origin server:
     - Japan Origin Server : **Public IP of Origin Server** 
        - **Public IPV4**: 54.199.129.154
        - Toggle the **Show Advanced Fields** option to reveal **Origin Server Labels**.
        - **Origin Server Labels**: arc-geolocation - Japan
        - Click **Apply** to save the configuration for the Japan origin server.
     - London Origin Server: **Public IP of Origin Server** 
        - **Public IPV4**: 16.60.207.154
        - Toggle the **Show Advanced Fields** option to reveal **Origin Server Labels**.
        - **Origin Server Labels**: arc-geolocation - London
        - Click **Apply** to save the configuration for the London origin server.
     - Virginia Origin Server: **Public IP of Origin Server** 
        - **Public IPV4**: 32.199.44.47
        - Toggle the **Show Advanced Fields** option to reveal **Origin Server Labels**.
        - **Origin Server Labels**: arc-geolocation - Virginia
        - Click **Apply** to save the configuration for the Virginia origin server.
3. Origin Server Port: **80**
4. In the **Health Checks** section, select **arcadia-na-hc** for the health check configuration.
5. In the **Other Settings** section, click **Configure**
6. In the **Origin Server Subsets** section, select **Enable Subset Load Balancing** and click **Configure** to specify the following details:
   - In the **Origin Server Subset Classes** section, click **Add-Item**
   - Under **List of keys for subnet**, enter your key label from Step 2: **arc-geolocation**
   - Click **Apply** to add the key label 
7. In the **Subset Fallback Policy** section, choose the **Select Any Origin Server** option to allow the load balancer to select any available healthy origin server if no matching subset is found.
8. Click **Apply** twice to save the configuration and return to the **Other Settings** section of the Origin Pool configuration.
9. Click **Add Origin Pool** to save the origin pool configuration.

### Step 3: Create an HTTP Load Balancer
1. In the F5 Distributed Cloud Console, navigate to **Multi-Cloud App Connect** > **Load Balancers** > **HTTP Load Balancers**.
2. Select **Add HTTP Load Balancer** and specify the following details:
   - Name: **arcadia-gs-hlb1**
   - Domains: **arcadia.f5training1.cloud**
   - In the **Load Balancer Type** section, check all appropriate options.
   - In the Origins section, click **Add Origin Pool** and select the **arcadia-gs-op1** origin pool.
   - Click **Apply** to save the origin pool configuration.
3. In the **Origins** section, toggle the **Show Advanced Fields** option to reveal **Origin Server Subset Rules**.
4. Click **Configure** to specify the following details:
   - In the **Subset Rules** section, click **Add-Item**
   - For Subset Rule1, specify the following details:; 
          - Name: **eu-traffic**
          - Action: Select **Add-Label** Key: **arc-geolocation** > London
          - In the **Clients** section, select **Client Selector Match** > **Group of Clients by Label Selector** > **geoip.ves.io/country** > **GB**
          - Click **Apply** to save the configuration for the first subset rule.
    - For Subset Rule2, specify the following details:
          - Name: **us-traffic**
          - Action: Select **Add-Label** Key: **arc-geolocation** > Virginia
          - In the **Clients* section, select **Client Selector Match** > **Group of Clients by Label Selector** > **geoip.ves.io/country** > **US**
          - Click **Apply** to save the configuration for the second subset rule.
    - For Subset Rule3, specify the following details:
          - Name: **jp-traffic**
          - Action: Select **Add-Label** Key: **arc-geolocation** > Japan
          - In the **Clients* section, select **Client Selector Match** > **Group of Clients by Label Selector** > **geoip.ves.io/country** > **JP**
          - Click **Apply** to save the configuration for the third subset rule.
5. Click **Apply** to save the subset rules configuration and return to the **Origins** section of the HTTP Load Balancer configuration.
6. Click **Save HTTP Load Balancer** to save the configuration.

### Test Intelligent Traffic Steering on HTTP LB
1. Once the HTTP LB has successfully been provisioned and is showing "valid" state
2. Connect to your application from different locations (Japan, London or Virginia) using a VPN (preferably).
3. Verify if the version of your application matches the version hosted on that specific region. 

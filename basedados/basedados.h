<%@ page import="java.sql.*" %>
<%!

private static final String DB_HOST = "localhost";
private static final String DB_PORT = "3306";      
private static final String DB_NAME = "felixubershop";
private static final String DB_USER = "root";
private static final String DB_PASS = "";

/* URL JDBC (MySQL 8+) */
private static final String DB_URL = "jdbc:mysql://" + DB_HOST + ":" + DB_PORT + "/" + DB_NAME +
    "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=UTF-8";

/* 1) Abrir ligação */
public Connection dbConnect() throws SQLException {
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
    } catch (ClassNotFoundException e) {
        throw new SQLException("Driver MySQL não encontrado. Verifica o connector/j.", e);
    }
    return DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
}

/* 2) Fechar recursos (sem rebentar se já estiverem null) */
public void dbClose(ResultSet rs, PreparedStatement ps, Connection con) {
    try { if (rs != null) rs.close(); } catch (Exception ignored) {}
    try { if (ps != null) ps.close(); } catch (Exception ignored) {}
    try { if (con != null) con.close(); } catch (Exception ignored) {}
}

/* 3) SELECT genérico (PreparedStatement) */
public ResultSet dbQuery(Connection con, PreparedStatement ps) throws SQLException {
    return ps.executeQuery();
}

/* 4) INSERT/UPDATE/DELETE genérico */
public int dbUpdate(Connection con, PreparedStatement ps) throws SQLException {
    return ps.executeUpdate();
}
%>
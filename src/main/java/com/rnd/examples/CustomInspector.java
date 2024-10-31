package com.rnd.examples;

import org.springframework.boot.autoconfigure.orm.jpa.HibernatePropertiesCustomizer;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * Copyright https://codesenior.com/en/tutorial/Truly-Implement-Soft-Delete-in-Spring-Boot-Hibernate
 */
@Component
public class CustomInspector implements StatementInspector {

    public String inspect(String sql) {
        if(sql.contains("user_roles")){
            System.out.println("user_roles");
        }
        sql = handleJoinClauses(sql);
        Pattern pattern = Pattern.compile("\\b(\\w+)\\.deleted\\b");
        Matcher matcher = pattern.matcher(sql);

        StringBuilder builder = new StringBuilder();

        while (matcher.find()) {
            String group = matcher.group(1);
            if (!containsDeletedClause(sql, group)) {
                builder.append(group).append(".deleted = false and ");
            }
        }

        if (builder.isEmpty()) return sql;
        int end = builder.length() - " and ".length();
        String conjunction = sql.contains(" where ") ? " and " : " where ";
        if (sql.contains("order by")) {
            int index = sql.indexOf(" order by");
            return sql.substring(0, index) + conjunction + builder.substring(0, end) + sql.substring(index);
        } else if (sql.contains("group by")) {
            int index = sql.indexOf(" group by");
            return sql.substring(0, index) + conjunction + builder.substring(0, end) + sql.substring(index);
        }
        return sql + conjunction + builder.substring(0, end);
    }

    private String handleJoinClauses(String sql) {
        Pattern joinPattern = Pattern.compile("(left\\s+(outer\\s+)?join|right\\s+outer\\s+join|join)\\s+(\\w+)\\s+(\\w+)\\s+on\\s+(\\w+\\.\\w+\\s*=\\s*\\w+\\.\\w+)");
        Matcher joinMatcher = joinPattern.matcher(sql);
        StringBuffer buffer = new StringBuffer();

        while (joinMatcher.find()) {
            String alias = joinMatcher.group(4); // corrected group index
            if (!containsDeletedClause(sql, alias)) {
                String replacement = joinMatcher.group(0) + " and " + alias + ".deleted = 0"; // Add the new condition
                joinMatcher.appendReplacement(buffer, replacement);
            }
        }
        joinMatcher.appendTail(buffer);
        return buffer.toString();
    }
    private boolean containsDeletedClause(String sql, String group) {
        if (sql.contains(group + ".deleted = false")) return true;
        if (sql.contains(group + ".deleted = 0")) return true;
        if (sql.contains(group + ".deleted = 1")) return true;
        if (sql.contains(group + ".deleted = true")) return true;
        if (sql.contains(group + ".deleted = ?")) return true;
        if (sql.contains(group + ".deleted=false")) return true;
        if (sql.contains(group + ".deleted=true")) return true;
        if (sql.contains(group + ".deleted=?")) return true;
        if (sql.contains(group + ".deleted= false")) return true;
        if (sql.contains(group + ".deleted= true")) return true;
        if (sql.contains(group + ".deleted= ?")) return true;
        if (sql.contains(group + ".deleted =false")) return true;
        if (sql.contains(group + ".deleted =true")) return true;
        if (sql.contains(group + ".deleted =?")) return true;
        return false;


    }
}

@Component
class MyInterceptorRegistration implements HibernatePropertiesCustomizer {

    private final CustomInspector customInspector;

    public MyInterceptorRegistration(CustomInspector customInspector) {
        this.customInspector = customInspector;
    }

    @Override
    public void customize(Map<String, Object> hibernateProperties) {
        hibernateProperties.put("hibernate.session_factory.statement_inspector", customInspector);
    }
}

